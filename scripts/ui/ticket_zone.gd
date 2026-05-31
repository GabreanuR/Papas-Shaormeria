extends Control

func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY \
		and data.has("este_bilet_comanda") \
		and data.has("nod_bilet") \
		and is_instance_valid(data["nod_bilet"])


func _drop_data(_pos: Vector2, data: Variant) -> void:
	var ticket: Control = data["nod_bilet"]

	get_tree().call_group("drop_layer", "clear_pinned_ticket", ticket)

	# --- Prevenim bug-ul cârligelor goale! ---
	var parinte = ticket.get_parent()
	if parinte != null and parinte.get_parent() == self:
		# Lăsăm biletul fix cum era nativ
		if ticket.has_method("set_locked_large"):
			ticket.set_locked_large(false)
		return 
	# ----------------------------------------------

	var hook := Control.new()
	hook.custom_minimum_size = Vector2(45, 65)
	hook.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(hook)
	ticket.reparent(hook)

	if ticket.has_method("set_locked_large"):
		ticket.set_locked_large(false)

	ticket.position = hook.custom_minimum_size / 2.0
	ticket.show()
