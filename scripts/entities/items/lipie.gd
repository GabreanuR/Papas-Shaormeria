extends TextureRect

@onready var container_lipie = get_node("../MascaLipie/IngredientePeLipie")
@onready var container_mizerie = get_tree().current_scene.find_child("MizerieMasa")

var ingrediente_puse = []
var sos_curent = null
var puncte_scor = []
var mod_sos_activ = false
var sticla_vizuala = null
var punctaj_sos : float = 100.0
var numar_picaturi_ideale : int = 250 

func _ready():
	for x in range(-120, 121, 60):
		for y in range(-120, 121, 60):
			puncte_scor.append(Vector2(x, y))

func _can_drop_data(_at_position, data):
	return typeof(data) == TYPE_DICTIONARY and (data.has("nume") or data.has("este_sos"))

func _drop_data(_at_position, data):
	var mouse_pos = get_global_mouse_position()
	
	if data.has("este_sos") and data["este_sos"] == true:
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
		sticla_vizuala.scale = Vector2(1.0, 1.0)
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
			
	if container_mizerie:
		var rest_masa = Sprite2D.new()
		rest_masa.texture = textura_finala
		container_mizerie.add_child(rest_masa)
		rest_masa.global_position = mouse_pos
		rest_masa.rotation = rot_random
		rest_masa.modulate = Color(0.7, 0.7, 0.7)
		
		if este_mic:
			if data["nume"] == "Chilli flakes":
				rest_masa.scale = Vector2(0.5, 0.5)
			else:
				rest_masa.scale = Vector2(0.9, 0.9)
		rest_masa.add_to_group("mizerie")

func _process(_delta):
	if mod_sos_activ and is_instance_valid(sticla_vizuala):
		sticla_vizuala.global_position = get_global_mouse_position()
		sticla_vizuala.offset = Vector2(0, 125) 

func _input(event):
	if mod_sos_activ:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					if sos_curent: sos_curent.activ = true
				else:
					if sos_curent: sos_curent.activ = false
			
			if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
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
		sos_curent = null
		
	var camera = get_viewport().get_camera_2d()
	if camera:
		var active_tweens = get_tree().get_processed_tweens()
		for t in active_tweens:
			t.kill() 

		camera.zoom = Vector2(1.0, 1.0)
		camera.global_position = Vector2(1945, 0) 

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
	
	print("--- REZULTAT FINAL SOS ---")
	print("Picături pe shaorma: ", nr_bune)
	print("Picături pe masă: ", nr_rele)
	print("Scor: ", int(scor_final), "%")
	
	return scor_final
