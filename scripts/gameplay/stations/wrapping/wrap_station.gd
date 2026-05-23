extends Control

@export var assembled_pita_scale := Vector2(0.25, 0.25)
@export var wrap_step_textures: Array[Texture2D]

@export var paper_1_texture: Texture2D
@export var paper_2_texture: Texture2D
@export var wrapped_with_paper_1_texture: Texture2D
@export var wrapped_with_paper_2_texture: Texture2D

@onready var wrap_area = $WrapGestureArea
@onready var tray = $Tray
@onready var ticket = $Ticket
@onready var ticket_slot_sprite = $Tray/TicketSlot/Sprite2D
@onready var send_button = $Tray/SendButton
@onready var darken = $Tray/SendButton/Darken
@onready var fade = $FadeOverlay

@onready var pita_preview: Node2D = $Tray/PitaPreview
@onready var wrapped_visual: Sprite2D = $Tray/WrappedVisual

@onready var paper_pile_1: TextureButton = $Tray/PaperPile1
@onready var paper_pile_2: TextureButton = $Tray/PaperPile2
@onready var carried_paper: Sprite2D = $Tray/CarriedPaper

var assembled_pita: Node2D = null
var wrap_quality: float = 0.0
var pending_wrap_quality: float = 0.0
var ticket_placed := false
var carrying_paper := false
var paper_applied := false
var carried_final_texture: Texture2D = null


func _ready() -> void:
	wrap_area.wrap_step_changed.connect(_on_wrap_step_changed)
	wrap_area.wrap_completed.connect(_on_wrap_done)

	paper_pile_1.button_down.connect(_on_paper_pile_1_pressed)
	paper_pile_2.button_down.connect(_on_paper_pile_2_pressed)

	wrapped_visual.hide()
	pita_preview.show()
	carried_paper.hide()

	_set_paper_piles_enabled(true)

func _process(_delta: float) -> void:
	if carrying_paper:
		carried_paper.global_position = get_global_mouse_position()


func _on_wrap_step_changed(step_index: int) -> void:
	if step_index < 0:
		wrapped_visual.hide()
		pita_preview.show()
		return

	if step_index >= wrap_step_textures.size():
		return

	if step_index == 0:
		pita_preview.hide()

	wrapped_visual.texture = wrap_step_textures[step_index]
	wrapped_visual.show()


func _on_wrap_done(quality: float) -> void:
	pending_wrap_quality = quality


func _on_paper_pile_1_pressed() -> void:
	_pick_paper(paper_1_texture, wrapped_with_paper_1_texture)


func _on_paper_pile_2_pressed() -> void:
	_pick_paper(paper_2_texture, wrapped_with_paper_2_texture)


func _pick_paper(carried_texture: Texture2D, final_texture: Texture2D) -> void:
	if pending_wrap_quality <= 0.0 or paper_applied:
		return

	if carried_texture == null or final_texture == null:
		return

	carrying_paper = true
	carried_final_texture = final_texture
	carried_paper.texture = carried_texture
	carried_paper.show()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and not event.pressed:
		if carrying_paper:
			if _is_mouse_over_wrapped_visual(get_global_mouse_position()):
				_apply_paper_to_shaorma()
			else:
				_cancel_carried_paper()

	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		if ticket_placed and is_mouse_over_send(get_global_mouse_position()):
			get_viewport().set_input_as_handled()
			_on_send_pressed()


func _apply_paper_to_shaorma() -> void:
	carrying_paper = false
	paper_applied = true
	wrap_quality = pending_wrap_quality

	carried_paper.hide()

	if carried_final_texture != null:
		wrapped_visual.texture = carried_final_texture

	_set_paper_piles_enabled(false)

func _cancel_carried_paper() -> void:
	carrying_paper = false
	carried_paper.hide()


func _is_mouse_over_wrapped_visual(mouse_pos: Vector2) -> bool:
	if wrapped_visual.texture == null:
		return false

	var local_mouse_pos := wrapped_visual.to_local(mouse_pos)
	return wrapped_visual.get_rect().has_point(local_mouse_pos)


func _set_paper_piles_enabled(enabled: bool) -> void:
	paper_pile_1.disabled = not enabled
	paper_pile_2.disabled = not enabled


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return paper_applied \
		and wrap_quality > 0.0 \
		and typeof(data) == TYPE_DICTIONARY \
		and data.has("este_bilet_comanda")


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	ticket_placed = true

	if data.has("nod_bilet") and is_instance_valid(data["nod_bilet"]):
		data["nod_bilet"].queue_free()

	ticket.global_position = ticket_slot_sprite.global_position
	ticket.reparent(tray)
	ticket.show()

	darken.visible = false
	darken.modulate.a = 0.0


func _on_send_pressed() -> void:
	if not ticket_placed:
		return

	var tween := create_tween()
	tween.tween_property(tray, "position:x", tray.position.x + 1800, 0.85)

	var fade_tween := create_tween()
	fade_tween.tween_property(fade, "modulate:a", 1.0, 0.85)


func is_mouse_over_send(mouse_pos: Vector2) -> bool:
	if send_button is Control:
		return send_button.get_global_rect().has_point(mouse_pos)

	return mouse_pos.distance_to(send_button.global_position) < 120.0


func receive_pita_from_assembly(source_lipie_container: Node, _pita_state: Dictionary) -> void:
	if source_lipie_container == null:
		return

	if not source_lipie_container is Node2D:
		return

	assembled_pita = source_lipie_container as Node2D
	assembled_pita.reparent(pita_preview)

	assembled_pita.visible = true
	assembled_pita.modulate.a = 1.0
	assembled_pita.z_index = 10
	assembled_pita.scale = assembled_pita_scale

	var visual_bounds := _get_visual_bounds(assembled_pita)

	if visual_bounds.size != Vector2.ZERO:
		assembled_pita.position = -visual_bounds.get_center() * assembled_pita_scale
	else:
		assembled_pita.position = Vector2.ZERO

	pita_preview.visible = true
	pita_preview.modulate.a = 1.0


func _get_visual_bounds(root: Node2D) -> Rect2:
	var bounds := Rect2()
	var has_bounds := false

	for child in root.get_children():
		if child is CanvasItem:
			var child_bounds := _get_canvas_item_bounds(child, root)

			if child_bounds.size != Vector2.ZERO:
				if has_bounds:
					bounds = bounds.merge(child_bounds)
				else:
					bounds = child_bounds
					has_bounds = true

	return bounds


func _get_canvas_item_bounds(item: CanvasItem, root: Node2D) -> Rect2:
	var bounds := Rect2()
	var has_bounds := false

	if item is Sprite2D:
		var sprite := item as Sprite2D

		if sprite.texture != null:
			var size := sprite.texture.get_size()
			var rect_position := Vector2.ZERO

			if sprite.centered:
				rect_position = -size * 0.5

			var rect := Rect2(rect_position, size)
			var transform_to_root := root.global_transform.affine_inverse() * sprite.global_transform

			var points := [
				transform_to_root * rect.position,
				transform_to_root * (rect.position + Vector2(rect.size.x, 0)),
				transform_to_root * (rect.position + Vector2(0, rect.size.y)),
				transform_to_root * (rect.position + rect.size)
			]

			var min_point: Vector2 = points[0]
			var max_point: Vector2 = points[0]

			for point in points:
				min_point = min_point.min(point)
				max_point = max_point.max(point)

			bounds = Rect2(min_point, max_point - min_point)
			has_bounds = true

	for child in item.get_children():
		if child is CanvasItem:
			var child_bounds := _get_canvas_item_bounds(child, root)

			if child_bounds.size != Vector2.ZERO:
				if has_bounds:
					bounds = bounds.merge(child_bounds)
				else:
					bounds = child_bounds
					has_bounds = true

	return bounds
