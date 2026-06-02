extends TextureRect

@onready var container_lipie = get_node("../MascaLipie/IngredientePeLipie")
@onready var container_mizerie = get_tree().current_scene.find_child("MizerieMasa")

var meat_sprite: Sprite2D = null

var meat_on_pita := {
	"chicken": {
		"texture": preload("res://assets/graphics/ingredients/carne_pui.png"),
		"position": Vector2(0, 0),
		"scale": Vector2(1, 1)
	},
	"beef": {
		"texture": preload("res://assets/graphics/ingredients/carne_vita.png"),
		"position": Vector2(0, 0),
		"scale": Vector2(1, 1)
	}
}

var ingrediente_puse = []
var sos_curent = null
var puncte_scor = []
var mod_sos_activ = false
var sticla_vizuala = null
var punctaj_sos : float = 100.0
var numar_picaturi_ideale : int = 60


func _ready():
	get_parent().visible = false

	for x in range(-120, 121, 60):
		for y in range(-120, 121, 60):
			puncte_scor.append(Vector2(x, y))

func _can_drop_data(_at_position, data):
	return typeof(data) == TYPE_DICTIONARY and (data.has("nume") or data.has("este_sos"))

func _drop_data(_at_position, data):
	var mouse_pos = get_global_mouse_position()
	
	if data.has("este_sos") and data["este_sos"] == true:
		if data.has("nume"):
			ingrediente_puse.append(data["nume"])
			
		var camera = get_viewport().get_camera_2d()
		if camera:
			var tween = create_tween()
			tween.parallel().tween_property(camera, "zoom", Vector2(1.5, 1.5), 0.8)
			tween.parallel().tween_property(camera, "global_position", Vector2(2275, 350), 0.8)
		
		var nod_sticle = get_tree().current_scene.find_child("SaucesStation", true, false)
		if nod_sticle:
			nod_sticle.visible = false

		sticla_vizuala = Sprite2D.new()
		sticla_vizuala.texture = data["poza"]
		sticla_vizuala.scale = Vector2(0.7, 0.7)
		sticla_vizuala.rotation = PI
		sticla_vizuala.offset = Vector2(0, 150)
		sticla_vizuala.z_index = 4096 
		sticla_vizuala.z_as_relative = false
		
		get_tree().current_scene.add_child(sticla_vizuala) 
		
		mod_sos_activ = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var instanta = data["scena_pata"].instantiate()
		if "culoare_sos" in instanta:
			instanta.culoare_sos = data["culoare"]
		
		get_tree().current_scene.add_child(instanta)
		get_tree().current_scene.move_child(instanta, -1)
		
		sos_curent = instanta
		return
		
	var rot_random = randf_range(0, 6.28)
	ingrediente_puse.append(data["nume"])
	
	var textura_finala = data["poza"]
	var este_mic = false
	
	if data.has("poza_shaorma") and data["poza_shaorma"] != null:
		textura_finala = data["poza_shaorma"]
		este_mic = true
	
	var clona_lipie = Sprite2D.new()
	clona_lipie.texture = textura_finala
	container_lipie.add_child(clona_lipie)
	clona_lipie.position = container_lipie.to_local(mouse_pos)
	clona_lipie.rotation = rot_random
	clona_lipie.modulate = Color(1, 1, 1, 1)
	
	if este_mic:
		if data["nume"] == "Chilli flakes":
			clona_lipie.scale = Vector2(0.5, 0.5)
		else:
			clona_lipie.scale = Vector2(0.9, 0.9)
			
	var marime_lipie = get_rect().size * scale
	var centru_shaorma = global_position + (marime_lipie / 2)
	var distanta = mouse_pos.distance_to(centru_shaorma)
	
	
	if distanta > 130.0 and container_mizerie:
		var rest_masa = Sprite2D.new()
		
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
					
		rest_masa.texture = ImageTexture.create_from_image(img)
		
		container_mizerie.add_child(rest_masa)
		rest_masa.global_position = mouse_pos
		rest_masa.rotation = rot_random
		rest_masa.modulate = Color(0.7, 0.7, 0.7)
		
		rest_masa.scale = Vector2(factor_scala, factor_scala)
		rest_masa.add_to_group("mizerie")

func _process(_delta):
	if mod_sos_activ and is_instance_valid(sticla_vizuala):
		sticla_vizuala.global_position = get_global_mouse_position()
		sticla_vizuala.offset = Vector2(0, 200) 

func _input(event):
	if mod_sos_activ:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					if sos_curent: sos_curent.activ = true
				else:
					if sos_curent: sos_curent.activ = false
			
			if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				var gm = get_tree().current_scene
				if gm and gm.has_method("finish_sauce_mode"):
					gm.finish_sauce_mode()
				else:
					finalizeaza_minigame_sos()

func finalizeaza_minigame_sos():
	mod_sos_activ = false
	mouse_filter = Control.MOUSE_FILTER_STOP 
	
	var grup_sticle = get_tree().current_scene.find_child("SaucesStation", true, false)
	
	if grup_sticle:
		grup_sticle.visible = true

	if sticla_vizuala:
		sticla_vizuala.queue_free()
		sticla_vizuala = null
	
	if sos_curent:
		calculeaza_scor_sos()
		if sos_curent.has_method("finish_sauce"):
			sos_curent.finish_sauce()
		sos_curent = null

func calculeaza_scor_sos():
	var picaturi_bune = get_tree().get_nodes_in_group("sos_pe_lipie")
	var picaturi_rele = get_tree().get_nodes_in_group("sos_pe_masa")
	
	var nr_bune = picaturi_bune.size()
	var nr_rele = picaturi_rele.size()
	
	var diferenta = abs(nr_bune - numar_picaturi_ideale)
	var scor_topping = 100.0 - (diferenta * 0.2)
	scor_topping = clamp(scor_topping, 0, 100)
	
	var penalizare_mizerie = nr_rele * 1.5
	
	var scor_final = scor_topping - penalizare_mizerie
	scor_final = clamp(scor_final, 0, 100)
	

	
	return scor_final
	
	
func update_from_cutting(prepared_data: Dictionary = {}) -> void:
	var gameplay_master = get_tree().current_scene
	var pita_state: Dictionary = prepared_data

	if pita_state.is_empty() and gameplay_master and "current_pita_state" in gameplay_master:
		pita_state = gameplay_master.current_pita_state

	var meat_type = pita_state.get("meat_type", "")
	var is_cut = pita_state.get("is_cut", true)

	for child in container_lipie.get_children():
		child.queue_free()

	for child in get_children():
		if child.is_in_group("sos_pe_lipie"):
			child.queue_free()

	meat_sprite = null
	ingrediente_puse.clear()

	if meat_type == "" or not is_cut:
		get_parent().visible = false
		return
		
	get_parent().visible = true

	if not meat_on_pita.has(meat_type):
		return

	meat_sprite = Sprite2D.new()
	meat_sprite.name = "GeneratedMeatOnPita"

	var meat_data = meat_on_pita[meat_type]
	meat_sprite.texture = meat_data["texture"]
	meat_sprite.position = meat_data["position"]
	meat_sprite.scale = meat_data["scale"]
	meat_sprite.visible = true

	container_lipie.add_child(meat_sprite)


func calculeaza_scor_assembly(reteta_ceruta: Array) -> int:
	var scor_ingrediente := 100.0
	var puse = ingrediente_puse.duplicate()
	
	# FIX: Ignorăm lucrurile care NU țin de Assembly (carne, lipie, sucuri)
	var de_ignorat = ["lipie", "carne_pui", "carne_vita", "chicken", "beef", "suc_cola", "suc_portocale", "suc_lamaie"]
	var cerute = []
	for item in reteta_ceruta:
		if not item in de_ignorat:
			cerute.append(item)
	
	var pointer_puse = 0
	
	# Verificăm ce a cerut clientul
	for i in range(cerute.size()):
		var item_cautat = cerute[i]
		var gasit_in_ordine = false
		
		for j in range(pointer_puse, puse.size()):
			if puse[j] == item_cautat:
				gasit_in_ordine = true
				puse[j] = null
				pointer_puse = j + 1
				break
				
		if not gasit_in_ordine:
			var gasit_oriunde = false
			for j in range(puse.size()):
				if puse[j] == item_cautat:
					gasit_oriunde = true
					puse[j] = null
					break
			
			if gasit_oriunde:
				scor_ingrediente -= 5.0 # L-ai pus, dar în ordinea greșită
			else:
				scor_ingrediente -= 15.0 # Ai uitat complet ingredientul!
				
	# Orice a rămas în lista 'puse' înseamnă că e ceva în PLUS
	for item in puse:
		if item != null:
			scor_ingrediente -= 10.0 # Depunctare pentru ingrediente extra
			
	scor_ingrediente = clamp(scor_ingrediente, 0, 100)
	
	# Media cu minigame-ul de sos
	var scor_sos = calculeaza_scor_sos()
	var scor_total = (scor_ingrediente * 0.6) + (scor_sos * 0.4)
	
	return int(clamp(scor_total, 0, 100))
