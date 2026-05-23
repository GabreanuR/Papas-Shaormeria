extends Control

@export var assembled_pita_scale := Vector2(0.25, 0.25)
@export var wrap_step_textures: Array[Texture2D]

@onready var wrap_area = $WrapGestureArea
@onready var tray = $Tray
@onready var ticket = $Ticket
@onready var ticket_slot_sprite = $Tray/TicketSlot/Sprite2D
@onready var send_button = $Tray/SendButton
@onready var darken = $Tray/SendButton/Darken
@onready var fade = $FadeOverlay

@onready var pita_preview: Node2D = $Tray/PitaPreview
@onready var wrapped_visual: Sprite2D = $Tray/WrappedVisual

var assembled_pita: Node2D = null
var wrap_quality: float = 0.0
var ticket_placed := false


func _ready() -> void:
	wrap_area.wrap_step_changed.connect(_on_wrap_step_changed)
	wrap_area.wrap_completed.connect(_on_wrap_done)

	wrapped_visual.hide()
	pita_preview.show()


func _on_wrap_step_changed(step_index: int) -> void:
	if step_index < 0:
		wrapped_visual.hide()
		pita_preview.show()
		return

	if step_index >= wrap_step_textures.size():
		return

	# La primul swipe ascundem pita reală
	if step_index == 0:
		pita_preview.hide()

	wrapped_visual.texture = wrap_step_textures[step_index]
	wrapped_visual.show()

func _on_wrap_done(quality: float) -> void:
	wrap_quality = quality


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return wrap_quality > 0.0 \
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


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		if ticket_placed and is_mouse_over_send(get_global_mouse_position()):
			get_viewport().set_input_as_handled()
			_on_send_pressed()


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
