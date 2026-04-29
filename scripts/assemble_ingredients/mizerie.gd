extends TextureRect

func _can_drop_data(_at_position, data):
	return typeof(data) == TYPE_DICTIONARY

func _drop_data(_at_position, data):
	var mouse_pos = get_global_mouse_position()
	
	var textura_finala = data["poza"]
	var este_mic = false
	
	if data.has("poza_shaorma") and data["poza_shaorma"] != null:
		textura_finala = data["poza_shaorma"]
		este_mic = true
	
	var rest_masa = Sprite2D.new()
	rest_masa.texture = textura_finala
	
	add_child(rest_masa)
	rest_masa.global_position = mouse_pos
	rest_masa.z_index = 1
	rest_masa.modulate = Color(0.7, 0.7, 0.7)
	if este_mic:
		if data["nume"] == "Chilli flakes":
			rest_masa.scale = Vector2(0.5, 0.5)
		else:
			rest_masa.scale = Vector2(0.9, 0.9)
	rest_masa.add_to_group("mizerie")
