extends Node2D

@onready var wrap_area = $WrapGestureArea
@onready var tray = $Tray
@onready var ticket = $Ticket
@onready var ticket_slot_sprite = $Tray/TicketSlot/Sprite2D
@onready var send_button = $Tray/SendButton
@onready var darken = $Tray/SendButton/Darken
@onready var fade = $FadeOverlay

var wrap_quality: float = 0.0
var can_drag_ticket := false
var is_dragging_ticket := false
var ticket_placed := false
var ticket_offset := Vector2.ZERO

var slot_area_size := Vector2(500, 500)


func _ready():
	print("WRAP STATION READY")

	wrap_area.wrap_completed.connect(_on_wrap_done)

	ticket.visible = true
	ticket.z_index = 200

	send_button.visible = true
	darken.visible = true
	darken.modulate.a = 0.65

	fade.modulate.a = 0.0


func _on_wrap_done(quality: float):
	print("Wrapping finished:", quality)

	wrap_quality = quality
	can_drag_ticket = true

	print("Ticket drag activat")


func _input(event):
	var mouse_pos: Vector2 = get_global_mouse_position()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if can_drag_ticket and not ticket_placed:
				is_dragging_ticket = true
				ticket_offset = ticket.global_position - mouse_pos
				ticket.z_index = 200
				print("Start drag ticket")

			elif ticket_placed and is_mouse_over_send(mouse_pos):
				_on_send_pressed()

		else:
			if is_dragging_ticket:
				is_dragging_ticket = false
				check_ticket_drop(mouse_pos)

	elif event is InputEventMouseMotion and is_dragging_ticket:
		ticket.global_position = mouse_pos + ticket_offset
		ticket.scale = Vector2(1.1, 1.1)


func check_ticket_drop(mouse_pos: Vector2):
	ticket.scale = Vector2.ONE

	if get_slot_area().has_point(mouse_pos):
		ticket_placed = true
		can_drag_ticket = false
		is_dragging_ticket = false

		var target_pos: Vector2 = get_slot_center()

		ticket.global_position = target_pos

		var old_global_pos: Vector2 = ticket.global_position
		ticket.reparent(tray)
		ticket.global_position = old_global_pos
		ticket.z_index = 200

		darken.visible = false
		darken.modulate.a = 0.0

		print("Ticket placed and attached to tray!")
	else:
		print("Ticket NOT in slot area")


func _on_send_pressed():
	if not ticket_placed:
		print("Nu poti trimite comanda pana nu pui ticketul.")
		return

	print("Trimitem comanda cu quality:", wrap_quality)

	var tween = create_tween()
	tween.tween_property(tray, "position:x", tray.position.x + 1800, 0.85)

	var fade_tween = create_tween()
	fade_tween.tween_property(fade, "modulate:a", 1.0, 0.85)


func get_slot_center() -> Vector2:
	return ticket_slot_sprite.global_position


func get_slot_area() -> Rect2:
	return Rect2(get_slot_center() - slot_area_size / 2.0, slot_area_size)


func is_mouse_over_send(mouse_pos: Vector2) -> bool:
	return mouse_pos.distance_to(send_button.global_position) < 120.0
