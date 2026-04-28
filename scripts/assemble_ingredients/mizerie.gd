extends TextureRect # sau Sprite2D dacă e cazul

func _can_drop_data(_at_position, data):
	print("Mouse-ul este peste masă cu un ingredient!") # Dacă nu vezi asta în consolă, fundalul nu vede mouse-ul
	return typeof(data) == TYPE_DICTIONARY

func _drop_data(_at_position, data):
	var mouse_pos = get_global_mouse_position()
	
	var rest_masa = Sprite2D.new()
	rest_masa.texture = data["poza"]
	
	# Adăugăm mizeria direct pe fundal sau pe nodul Table
	add_child(rest_masa)
	rest_masa.global_position = mouse_pos
	rest_masa.z_index = 1 # Să fie un pic deasupra fundalului, dar sub lipie
	rest_masa.modulate = Color(0.7, 0.7, 0.7)
	rest_masa.add_to_group("mizerie")
	
	print("Am scăpat ", data["nume"], " pe masă!")
