extends TextureRect

@onready var container_lipie = get_node("../MascaLipie/IngredientePeLipie")
@onready var container_mizerie = get_tree().current_scene.find_child("MizerieMasa")

var ingrediente_puse = []

func _can_drop_data(_at_position, data):
	return typeof(data) == TYPE_DICTIONARY and data.has("nume")

func _drop_data(_at_position, data):
	var mouse_pos = get_global_mouse_position()
	var rot_random = randf_range(0, 6.28)
	
	ingrediente_puse.append(data["nume"])
	print("Shaorma actuala contine: ", ingrediente_puse)
	
	var clona_lipie = Sprite2D.new()
	clona_lipie.texture = data["poza"]
	container_lipie.add_child(clona_lipie)
	clona_lipie.position = container_lipie.to_local(mouse_pos)
	clona_lipie.rotation = rot_random
	
	if container_mizerie:
		var rest_masa = Sprite2D.new()
		rest_masa.texture = data["poza"]
		container_mizerie.add_child(rest_masa)
		rest_masa.global_position = mouse_pos
		rest_masa.rotation = rot_random
		rest_masa.modulate = Color(0.7, 0.7, 0.7)
		rest_masa.add_to_group("mizerie")
