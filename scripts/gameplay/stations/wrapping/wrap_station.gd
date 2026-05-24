extends Control

@export var assembled_pita_scale := Vector2(0.25, 0.25)
@export var wrap_step_textures: Array[Texture2D]

@export var paper_1_texture: Texture2D
@export var paper_2_texture: Texture2D
@export var wrapped_with_paper_1_texture: Texture2D
@export var wrapped_with_paper_2_texture: Texture2D

@export var drink_1_texture: Texture2D
@export var drink_2_texture: Texture2D
@export var drink_3_texture: Texture2D

@onready var wrap_area = $WrapGestureArea
@onready var tray = $Tray
@onready var ticket_slot_area: Area2D = $Tray/TicketSlot/Area2D
@onready var ticket_slot_sprite = $Tray/TicketSlot/Sprite2D
@onready var send_button = $Tray/SendButton
@onready var darken = $Tray/SendButton/Darken
@onready var fade = $FadeOverlay

@onready var pita_preview: Node2D = $Tray/PitaPreview
@onready var wrapped_visual: Sprite2D = $Tray/WrappedVisual

@onready var paper_pile_1: TextureButton = $Tray/PaperPile1
@onready var paper_pile_2: TextureButton = $Tray/PaperPile2
@onready var carried_paper: Sprite2D = $Tray/CarriedPaper

@onready var drink_1: TextureButton = $Tray/Drink1
@onready var drink_2: TextureButton = $Tray/Drink2
@onready var drink_3: TextureButton = $Tray/Drink3
@onready var carried_drink: Sprite2D = $Tray/CarriedDrink
@onready var placed_drink: Sprite2D = $Tray/PlacedDrink
@onready var drink_drop_area: Control = $Tray/DrinkDropArea

var assembled_pita: Node2D = null
var wrap_quality: float = 0.0
var pending_wrap_quality: float = 0.0
var ticket_placed := false
var carrying_paper := false
var paper_applied := false
var carried_final_texture: Texture2D = null

var carrying_drink := false
var drink_placed := false
var selected_drink_button: TextureButton = null
var selected_drink_texture: Texture2D = null


func _ready() -> void:
	wrap_area.wrap_step_changed.connect(_on_wrap_step_changed)
	wrap_area.wrap_completed.connect(_on_wrap_done)

	paper_pile_1.button_down.connect(_on_paper_pile_1_pressed)
	paper_pile_2.button_down.connect(_on_paper_pile_2_pressed)

	wrapped_visual.hide()
	pita_preview.show()
	carried_paper.hide()

	_set_paper_piles_enabled(true)
	
	drink_1.button_down.connect(func(): _pick_drink(drink_1, drink_1_texture))
	drink_2.button_down.connect(func(): _pick_drink(drink_2, drink_2_texture))
	drink_3.button_down.connect(func(): _pick_drink(drink_3, drink_3_texture))

	carried_drink.hide()
	placed_drink.hide()

func _process(_delta: float) -> void:
	if carrying_paper:
		carried_paper.global_position = get_global_mouse_position()
	if carrying_drink:
		carried_drink.global_position = get_global_mouse_position()


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
		if carrying_drink:
			if _is_mouse_over_drink_drop_area(get_global_mouse_position()):
				_apply_drink_to_tray()
			else:
				_cancel_carried_drink()

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
		and not ticket_placed \
		and typeof(data) == TYPE_DICTIONARY \
		and data.has("este_bilet_comanda") \
		and _is_mouse_over_ticket_slot(get_global_mouse_position())


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if ticket_placed:
		return

	if not data.has("nod_bilet"):
		return

	var real_ticket = data["nod_bilet"]

	if not is_instance_valid(real_ticket):
		return

	ticket_placed = true

	real_ticket.modulate.a = 1.0
	real_ticket.is_locked_large = true
	real_ticket.is_in_wrapping_slot = true
	real_ticket.top_level = true
	real_ticket.scale = Vector2(0.35, 0.35)
	real_ticket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	real_ticket.z_index = 100

	real_ticket.global_position = ticket_slot_area.global_position - (real_ticket.size * real_ticket.scale) * 0.5

	ticket_slot_area.set_meta("current_ticket", real_ticket)

	darken.visible = false
	darken.modulate.a = 0.0


func _is_mouse_over_ticket_slot(mouse_pos: Vector2) -> bool:
	var shape := ticket_slot_area.get_node_or_null("CollisionShape2D")

	if shape == null or shape.shape == null or shape.disabled:
		return false

	var local_pos: Vector2 = shape.to_local(mouse_pos)

	if shape.shape is RectangleShape2D:
		var rect_shape := shape.shape as RectangleShape2D
		var rect := Rect2(-rect_shape.size * 0.5, rect_shape.size)
		return rect.has_point(local_pos)

	if shape.shape is CircleShape2D:
		var circle_shape := shape.shape as CircleShape2D
		return local_pos.length() <= circle_shape.radius

	return false

func _on_send_pressed() -> void:
	if not ticket_placed:
		return

	paper_pile_1.hide()
	paper_pile_2.hide()

	var tween := create_tween()
	tween.tween_property(tray, "position:x", tray.position.x + 1800, 0.85)
	tween.finished.connect(_reset_drinks)

	var fade_tween := create_tween()
	fade_tween.tween_property(fade, "modulate:a", 1.0, 0.85)


func is_mouse_over_send(mouse_pos: Vector2) -> bool:
	if send_button is Control:
		return send_button.get_global_rect().has_point(mouse_pos)

	return mouse_pos.distance_to(send_button.global_position) < 120.0

func _reset_wrap_visual_state() -> void:
	wrap_quality = 0.0
	pending_wrap_quality = 0.0
	paper_applied = false
	carrying_paper = false
	carried_final_texture = null

	carried_paper.hide()
	wrapped_visual.hide()

func receive_pita_from_assembly(source_lipie_container: Node, _pita_state: Dictionary) -> void:
	if source_lipie_container == null:
		return

	if not source_lipie_container is Node2D:
		return
		
	_reset_wrap_visual_state()

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
	
	
func _pick_drink(drink_button: TextureButton, drink_texture: Texture2D) -> void:
	if drink_placed or drink_texture == null:
		return

	carrying_drink = true
	selected_drink_button = drink_button
	selected_drink_texture = drink_texture

	drink_button.hide()
	carried_drink.texture = drink_texture
	carried_drink.show()


func _apply_drink_to_tray() -> void:
	carrying_drink = false
	drink_placed = true

	carried_drink.hide()
	placed_drink.texture = selected_drink_texture
	placed_drink.show()

	_disable_drinks()


func _cancel_carried_drink() -> void:
	carrying_drink = false
	carried_drink.hide()

	if selected_drink_button != null and not drink_placed:
		selected_drink_button.show()


func _is_mouse_over_drink_drop_area(mouse_pos: Vector2) -> bool:
	return drink_drop_area.get_global_rect().has_point(mouse_pos)


func _disable_drinks() -> void:
	drink_1.disabled = true
	drink_2.disabled = true
	drink_3.disabled = true
	
	
func _reset_drinks() -> void:
	carrying_drink = false
	drink_placed = false
	selected_drink_button = null
	selected_drink_texture = null

	carried_drink.hide()
	placed_drink.hide()

	drink_1.show()
	drink_2.show()
	drink_3.show()

	drink_1.disabled = false
	drink_2.disabled = false
	drink_3.disabled = false
	
	
