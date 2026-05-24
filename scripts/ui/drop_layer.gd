extends Control

var pinned_ticket: Control = null
var right_zone_width := 360.0

var dragging_ticket: Control = null
var original_parent: Node = null
var original_index := 0
var original_position := Vector2.ZERO

@onready var ticket_zone: Control = $"../../TopBar/HBoxContainer/TicketBackground/TicketZone"


func _ready() -> void:
	add_to_group("drop_layer")
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	anchor_left = 0
	anchor_top = 0
	anchor_right = 1
	anchor_bottom = 1
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0

	z_index = 100


func start_ticket_drag(ticket: Control) -> void:
	dragging_ticket = ticket
	original_parent = ticket.get_parent()
	original_index = ticket.get_index()
	original_position = ticket.position

	mouse_filter = Control.MOUSE_FILTER_STOP


func stop_ticket_drag() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	dragging_ticket = null
	original_parent = null
	original_index = 0
	original_position = Vector2.ZERO


func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY \
		and data.has("este_bilet_comanda") \
		and data.has("nod_bilet") \
		and is_instance_valid(data["nod_bilet"])


func _drop_data(pos: Vector2, data: Variant) -> void:
	var ticket: Control = data["nod_bilet"]

	if _try_drop_ticket_in_wrapping(ticket):
		stop_ticket_drag()
		return

	if _is_mouse_over_any_wrapping_ticket_slot():
		_restore_ticket_to_original_place(ticket)
		stop_ticket_drag()
		return

	if pos.x >= size.x - right_zone_width:
		_try_pin_ticket(ticket)
	else:
		_restore_ticket_to_original_place(ticket)

	stop_ticket_drag()


func _try_drop_ticket_in_wrapping(ticket: Control) -> bool:
	for node in get_tree().get_nodes_in_group("wrapping_station"):
		if node.has_method("try_accept_ticket_from_drop"):
			if node.try_accept_ticket_from_drop(ticket):
				if pinned_ticket == ticket:
					pinned_ticket = null
				return true

	return false


func _is_mouse_over_any_wrapping_ticket_slot() -> bool:
	for node in get_tree().get_nodes_in_group("wrapping_station"):
		if node.has_method("_is_mouse_over_ticket_slot"):
			if node._is_mouse_over_ticket_slot(get_global_mouse_position()):
				return true

	return false


func _try_pin_ticket(ticket: Control) -> void:
	if pinned_ticket != null \
			and is_instance_valid(pinned_ticket) \
			and pinned_ticket != ticket:
		_restore_ticket_to_original_place(ticket)
		return

	pinned_ticket = ticket

	var old_hook := ticket.get_parent()

	ticket.reparent(self)

	if old_hook != null \
			and old_hook != self \
			and old_hook.get_child_count() == 0:
		old_hook.queue_free()

	if ticket.has_method("set_locked_large"):
		ticket.set_locked_large(true)

	ticket.scale = Vector2(0.85, 0.85)
	ticket.position = Vector2(size.x - 520, 150)
	ticket.show()


func _restore_ticket_to_original_place(ticket: Control) -> void:
	if original_parent == null or not is_instance_valid(original_parent):
		return

	if pinned_ticket == ticket:
		pinned_ticket = null

	ticket.reparent(original_parent)
	original_parent.move_child(ticket, min(original_index, original_parent.get_child_count() - 1))

	if ticket.has_method("set_locked_large"):
		ticket.set_locked_large(false)

	ticket.scale = Vector2(0.25, 0.25)
	ticket.position = original_position
	ticket.show()


func clear_pinned_ticket(ticket: Control) -> void:
	if pinned_ticket == ticket:
		pinned_ticket = null
