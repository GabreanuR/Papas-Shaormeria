extends Node2D

var activ = false
var poate_pune = true
var culoare_sos = Color(1, 1, 1)
var textura_picatura = preload("res://assets/graphics/ingredients/sos_zig_zag_alb.png")

@onready var sos_sfx: AudioStreamPlayer = get_node_or_null("SosSFX")

## Cached references (set on first use to avoid repeated find_child calls)
var _lipie_ref: Control = null
var _gameplay_master_ref: Node = null

## Performance: only spawn a drop every N-th frame
const SPAWN_EVERY_N_FRAMES := 3
var _frame_counter := 0

## Safety: cap total drops to prevent runaway node creation
const MAX_DROPS := 300
var _drop_count := 0

@export var sauce_distance_threshold := 205.0

func _ready():
	pass

func _process(_delta):
	if activ:
		if sos_sfx and not sos_sfx.playing:
			sos_sfx.play()

		_frame_counter += 1
		if _frame_counter >= SPAWN_EVERY_N_FRAMES and _drop_count < MAX_DROPS:
			_frame_counter = 0
			creeaza_picatura()
	else:
		if sos_sfx and sos_sfx.playing:
			sos_sfx.stop()

func _get_lipie() -> Control:
	if _lipie_ref == null or not is_instance_valid(_lipie_ref):
		var scene_root = get_tree().current_scene
		if scene_root:
			_lipie_ref = scene_root.find_child("Lipie", true, false)
	return _lipie_ref

func _get_gameplay_master() -> Node:
	if _gameplay_master_ref == null or not is_instance_valid(_gameplay_master_ref):
		_gameplay_master_ref = get_tree().current_scene
	return _gameplay_master_ref

func creeaza_picatura():
	var pic = Sprite2D.new()
	pic.name = "PataSos"
	pic.texture = textura_picatura
	pic.scale = Vector2(0.08, 0.08)
	pic.rotation = randf_range(0, PI * 2)
	var m_pos = get_global_mouse_position()
	var lipie = _get_lipie()
	
	if lipie:
		var marime_lipie = lipie.get_rect().size * lipie.scale
		var centru_shaorma = lipie.global_position + (marime_lipie / 2)
		var distanta = m_pos.distance_to(centru_shaorma)

		if distanta < sauce_distance_threshold:
			lipie.add_child(pic)
			pic.global_position = m_pos
			
			if lipie.modulate != Color(1, 1, 1, 1) and lipie.modulate.r > 0:
				pic.modulate = Color(
					culoare_sos.r / lipie.modulate.r,
					culoare_sos.g / lipie.modulate.g,
					culoare_sos.b / lipie.modulate.b,
					culoare_sos.a
				)
			else:
				pic.modulate = culoare_sos
			
			pic.z_index = 5
			pic.add_to_group("sos_pe_lipie")
		else:
			if lipie and "container_mizerie" in lipie and lipie.container_mizerie:
				lipie.container_mizerie.add_child(pic)
				pic.position = lipie.container_mizerie.to_local(m_pos)
			else:
				get_tree().current_scene.add_child(pic)
				pic.global_position = m_pos
			
			pic.modulate = culoare_sos.darkened(0.2)
			pic.z_index = 1
			pic.add_to_group("sos_pe_masa")

	_drop_count += 1

	var gm = _get_gameplay_master()
	if gm and gm.has_method("restart_sauce_finish_timer"):
		gm.restart_sauce_finish_timer()

func finish_sauce() -> void:
	activ = false
	_drop_count = 0
	_frame_counter = 0

	for child in get_children():
		if child is Sprite2D:
			child.queue_free()

	remove_from_group("active_sauce_bottle")
