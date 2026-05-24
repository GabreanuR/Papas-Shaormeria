extends Control

var pinned_ticket: Control = null
var right_zone_width := 360.0

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

	z_index = 9999


func start_ticket_drag(_ticket: Control) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func stop_ticket_drag() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY \
		and data.has("este_bilet_comanda") \
		and data.has("nod_bilet") \
		and is_instance_valid(data["nod_bilet"])


func _drop_data(pos: Vector2, data: Variant) -> void:
	var ticket: Control = data["nod_bilet"]

	if pos.x >= size.x - right_zone_width:
		_try_pin_ticket(ticket)
	else:
		_return_to_ticket_bar(ticket)

	stop_ticket_drag()


func _try_pin_ticket(ticket: Control) -> void:
	if pinned_ticket != null \
			and is_instance_valid(pinned_ticket) \
			and pinned_ticket != ticket:
		_return_to_ticket_bar(ticket)
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

func _return_to_ticket_bar(ticket: Control) -> void:
	if ticket_zone == null:
		print("NU GASESC TicketZone")
		return

	if pinned_ticket == ticket:
		pinned_ticket = null

	var hook := Control.new()
	hook.custom_minimum_size = Vector2(45, 65)
	hook.mouse_filter = Control.MOUSE_FILTER_IGNORE

	ticket_zone.add_child(hook)
	ticket.reparent(hook)

	if ticket.has_method("set_locked_large"):
		ticket.set_locked_large(false)

	ticket.scale = Vector2(0.25, 0.25)
	ticket.position = hook.custom_minimum_size / 2.0
	ticket.show()


func clear_pinned_ticket(ticket: Control) -> void:
	if pinned_ticket == ticket:
		pinned_ticket = null
