extends Node2D

var activ = false
var poate_pune = true
var culoare_sos = Color(1, 1, 1)
var textura_picatura = preload("res://assets/graphics/ingredients/sos_zig_zag_alb.png") # Pune calea ta către poza cu picătura

func _process(_delta):
	if activ:
		creeaza_picatura()

func creeaza_picatura():
	var pic = Sprite2D.new()
	pic.name = "PataSos"
	pic.texture = textura_picatura
	pic.scale = Vector2(0.08, 0.08)
	pic.rotation = randf_range(0, PI * 2)
	pic.z_index = 0
	pic.z_as_relative = false
	
	var m_pos = get_global_mouse_position()
	var lipie = get_tree().current_scene.find_child("Lipie", true, false)
	
	if lipie:
		var marime_lipie = lipie.get_rect().size * lipie.scale
		var centru_shaorma = lipie.global_position + (marime_lipie / 2)
		var distanta = m_pos.distance_to(centru_shaorma)

		if distanta < 205: 
			lipie.add_child(pic)
			pic.global_position = m_pos
			pic.modulate = culoare_sos 
			pic.z_index = 5 
			pic.add_to_group("sos_pe_lipie")
		else:
			get_tree().current_scene.add_child(pic)
			pic.global_position = m_pos
			pic.modulate = culoare_sos.darkened(0.2)
			pic.z_index = 1 
			pic.add_to_group("sos_pe_masa")
