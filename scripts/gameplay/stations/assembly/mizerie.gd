extends TextureRect

func _can_drop_data(_at_position, data):
	return typeof(data) == TYPE_DICTIONARY and data.has("poza")

func _drop_data(_at_position, data):
	var mouse_pos = get_global_mouse_position()
	
	var textura_finala = data["poza"]
	var este_mic = false
	
	if data.has("poza_shaorma") and data["poza_shaorma"] != null:
		textura_finala = data["poza_shaorma"]
		este_mic = true
		
	var rest_masa = Sprite2D.new()
	var rot_random = randf_range(0, 6.28)
	
	var textura_de_aplicat = textura_finala
	
	var scene_root = get_tree().current_scene
	var lipie = scene_root.find_child("Lipie", true, false) if scene_root else null
	
	if lipie and lipie.get_parent().visible:
		var marime_lipie = lipie.get_rect().size * lipie.scale
		var centru_shaorma = lipie.global_position + (marime_lipie / 2)
		var distanta = mouse_pos.distance_to(centru_shaorma)
		
		if distanta < 110.0:
			rest_masa.queue_free()
			return
		elif distanta < 250.0: 
			var img: Image = textura_finala.get_image()
			if img.is_compressed():
				img.decompress()
			img.convert(Image.FORMAT_RGBA8)
			
			var img_size = img.get_size()
			var factor_scala = 1.0
			if este_mic:
				if data.has("nume") and data["nume"] == "Chilli flakes":
					factor_scala = 0.5
				else:
					factor_scala = 0.9
					
			var cos_r = cos(rot_random)
			var sin_r = sin(rot_random)
			
			var RAZA_TAIERE = 185.0 
			
			var offset_centru = Vector2(img_size.x / 2.0, img_size.y / 2.0)
			
			for x in range(img_size.x):
				for y in range(img_size.y):
					var local_x = (x - offset_centru.x) * factor_scala
					var local_y = (y - offset_centru.y) * factor_scala
					var rot_x = local_x * cos_r - local_y * sin_r
					var rot_y = local_x * sin_r + local_y * cos_r
					var pixel_global = mouse_pos + Vector2(rot_x, rot_y)
					
					if pixel_global.distance_to(centru_shaorma) < RAZA_TAIERE:
						img.set_pixel(x, y, Color(0, 0, 0, 0))
						
			textura_de_aplicat = ImageTexture.create_from_image(img)
	
	rest_masa.texture = textura_de_aplicat
	
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
	HealthInspection.register_dirty_node(rest_masa)
