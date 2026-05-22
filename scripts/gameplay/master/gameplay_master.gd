extends Node

# ---------------------------------------------------------
# 1. SIGNALS
# ---------------------------------------------------------

# ---------------------------------------------------------
# 2. ENUMS
# ---------------------------------------------------------

# ---------------------------------------------------------
# 3. CONSTANTS
# ---------------------------------------------------------
const ASSEMBLY_INGREDIENTS_CAMERA_POS := Vector2(380, 230)
const ASSEMBLY_SAUCES_CAMERA_POS := Vector2(2340, 230)
const LIPIE_INGREDIENTS_POS := Vector2(670, 570)
const LIPIE_SAUCES_POS := Vector2(2630, 570)

# ---------------------------------------------------------
# 4. PUBLIC VARIABLES
# ---------------------------------------------------------
# Aceasta este lipia fizică pe care o prepari ACUM. 
# Când o livrezi, o resetezi.
var current_pita_state: Dictionary = _new_pita_state()

static func _new_pita_state() -> Dictionary:
	return {
		"meat_type": "",
		"is_cut": false,
		"sauces": [],
		"vegetables": [],
		"scores": {
			"cutting": 0,
			"waiting": 0,
			"assembly": 0,
			"wrapping": 0
		},
		"total_score": 0
	}

func update_station_score(station_name: String, score: int) -> void:
	current_pita_state["scores"][station_name] = score

	var total := 0
	for station_score in current_pita_state["scores"].values():
		total += station_score

	current_pita_state["total_score"] = total


func save_current_pita() -> void:
	completed_pitas.append(current_pita_state.duplicate(true))
	current_pita_state = _new_pita_state()

var completed_pitas: Array[Dictionary] = []
# ---------------------------------------------------------
# 5. PRIVATE VARIABLES
# ---------------------------------------------------------
var _assembly_camera: Camera2D
var _sauce_finish_timer: Timer
var _go_to_sauces_button: Button
var _go_to_wrapping_button: Button

# ---------------------------------------------------------
# 6. ONREADY VARIABLES
# ---------------------------------------------------------
@onready var _order_station: Node = %OrderStation
@onready var _cutting_station: Node = %MeatSelect
@onready var _assembly_station: Node = %AssemblyStation
@onready var _wrapping_station: Node = %WrappingStation

@onready var _order_camera: Camera2D = _order_station.find_child("Camera2D", true, false)

@onready var _btn_order: Button = %BtnOrder
@onready var _btn_cutting: Button = %BtnCutting
@onready var _btn_assembly: Button = %BtnAssembly
@onready var _btn_wrapping: Button = %BtnWrapping

# ---------------------------------------------------------
# 7. GODOT ENGINE FUNCTIONS
# ---------------------------------------------------------
func _ready() -> void:
	_btn_order.pressed.connect(_go_to_order)
	_btn_cutting.pressed.connect(_go_to_cutting)
	_btn_assembly.pressed.connect(_go_to_assembly)
	_btn_wrapping.pressed.connect(_go_to_wrapping)
	_assembly_camera = _assembly_station.find_child("Camera2D", true, false)

	# Fix: Mutăm TopBar-ul în CanvasLayer ca să rămână mereu pe ecran, indiferent unde se duce camera!
	var top_bar = get_node_or_null("TopBar")
	if top_bar and $CanvasLayer:
		top_bar.reparent($CanvasLayer)

	_create_assembly_buttons()
	_create_sauce_finish_timer()

	# Navigate to the day transition screen when the day ends.
	Global.day_ended.connect(_on_day_ended)

	# Start on the order station by default.
	_go_to_order()

# ---------------------------------------------------------
# 8. PUBLIC FUNCTIONS
# ---------------------------------------------------------

# ---------------------------------------------------------
# 9. PRIVATE FUNCTIONS
# ---------------------------------------------------------

## Shows only the given station and hides all others.
func _show_only(station: Node) -> void:
	if station != _assembly_station:
		finish_sauce_mode()

	_order_station.hide()
	_cutting_station.hide()
	_assembly_station.hide()
	_wrapping_station.hide()

	if _go_to_sauces_button:
		_go_to_sauces_button.visible = false

	if _go_to_wrapping_button:
		_go_to_wrapping_button.visible = false

	station.show()

func _go_to_order() -> void:
	_reset_current_pita_state()
	_show_only(_order_station)
	_activate_camera_for(_order_station)

func _go_to_cutting() -> void:
	_show_only(_cutting_station)
	_activate_camera_for(_cutting_station)

func _go_to_assembly() -> void:
	_show_only(_assembly_station)

	if _assembly_camera:
		_assembly_camera.enabled = true
		_assembly_camera.position = ASSEMBLY_INGREDIENTS_CAMERA_POS
		_assembly_camera.make_current()

	var lipie = _assembly_station.find_child("Lipie", true, false)
	if lipie and lipie.has_method("update_from_cutting"):
		lipie.update_from_cutting()
	
	var lipie_container = _assembly_station.find_child("LipieContainer", true, false)
	var lipie_sprite = _assembly_station.find_child("Lipie", true, false)

	if lipie_container and lipie_sprite:
		var offset = LIPIE_INGREDIENTS_POS - lipie_sprite.global_position
		lipie_container.global_position += offset

	if _go_to_sauces_button:
		_go_to_sauces_button.visible = true

	if _go_to_wrapping_button:
		_go_to_wrapping_button.visible = false


func _go_to_wrapping() -> void:
	if _assembly_camera:
		_assembly_camera.enabled = false

	# We MUST finish sauce mode before reparenting, so the Lipie node can still be found
	finish_sauce_mode()

	var lipie_container = _assembly_station.find_child("LipieContainer", true, false)

	if lipie_container and _wrapping_station.has_method("receive_pita_from_assembly"):
		_wrapping_station.receive_pita_from_assembly(lipie_container, current_pita_state)

	_show_only(_wrapping_station)
	_activate_camera_for(_wrapping_station)


# ---------------------------------------------------------
# 10. SIGNAL CALLBACKS
# ---------------------------------------------------------
func _on_day_ended() -> void:
	get_tree().change_scene_to_file("res://scenes/day_management/day_transition.tscn")


func _create_assembly_buttons() -> void:
	_go_to_sauces_button = Button.new()
	_go_to_sauces_button.text = "➜"
	_go_to_sauces_button.position = Vector2(1680, 860)
	_go_to_sauces_button.size = Vector2(120, 80)
	_go_to_sauces_button.visible = false
	_go_to_sauces_button.z_index = 999

	$CanvasLayer.add_child(_go_to_sauces_button)
	_go_to_sauces_button.pressed.connect(_go_to_assembly_sauces)

	_go_to_wrapping_button = Button.new()
	_go_to_wrapping_button.text = "➜"
	_go_to_wrapping_button.position = Vector2(1680, 860)
	_go_to_wrapping_button.size = Vector2(120, 80)
	_go_to_wrapping_button.visible = false
	_go_to_wrapping_button.z_index = 999

	$CanvasLayer.add_child(_go_to_wrapping_button)
	_go_to_wrapping_button.pressed.connect(_go_to_wrapping)


func _go_to_assembly_sauces() -> void:
	if _assembly_camera == null:
		return

	if _go_to_sauces_button:
		_go_to_sauces_button.visible = false

	var lipie_container = _assembly_station.find_child("LipieContainer", true, false)
	var lipie_sprite = _assembly_station.find_child("Lipie", true, false)

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		_assembly_camera,
		"position",
		ASSEMBLY_SAUCES_CAMERA_POS,
		0.8
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	

	if lipie_container and lipie_sprite:
		var offset = LIPIE_SAUCES_POS - lipie_sprite.global_position
		var target_lipie_container_pos = lipie_container.global_position + offset

		tween.tween_property(
			lipie_container,
			"global_position",
			target_lipie_container_pos,
			0.8
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	if _go_to_wrapping_button:
		_go_to_wrapping_button.visible = true


func _activate_camera_for(station: Node) -> void:
	if _assembly_camera:
		_assembly_camera.enabled = false

	var station_camera: Camera2D = station.find_child("Camera2D", true, false)
	if station_camera:
		station_camera.enabled = true
		station_camera.make_current()
	elif _order_camera:
		_order_camera.enabled = true
		_order_camera.make_current()


func _reset_current_pita_state() -> void:
	current_pita_state = _new_pita_state()

func _create_sauce_finish_timer() -> void:
	_sauce_finish_timer = Timer.new()
	_sauce_finish_timer.wait_time = 5.0
	_sauce_finish_timer.one_shot = true
	add_child(_sauce_finish_timer)
	_sauce_finish_timer.timeout.connect(finish_sauce_mode)

func restart_sauce_finish_timer() -> void:
	if _sauce_finish_timer and _sauce_finish_timer.is_stopped():
		_sauce_finish_timer.start()
		
func finish_sauce_mode() -> void:
	if _assembly_station:
		var lipie = _assembly_station.find_child("Lipie", true, false)
		if lipie and lipie.has_method("finalizeaza_minigame_sos"):
			if lipie.mod_sos_activ:
				lipie.finalizeaza_minigame_sos()

	for preview in get_tree().get_nodes_in_group("sauce_drag_preview"):
		if preview and is_instance_valid(preview):
			preview.queue_free()
	
	get_viewport().gui_cancel_drag()
	get_viewport().gui_release_focus()

	if _sauce_finish_timer:
		_sauce_finish_timer.stop()

	if _assembly_camera:
		var tween := create_tween()
		tween.set_parallel(true)

		tween.tween_property(
			_assembly_camera,
			"position",
			ASSEMBLY_SAUCES_CAMERA_POS,
			0.4
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		tween.tween_property(
			_assembly_camera,
			"zoom",
			Vector2(1, 1),
			0.4
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if _go_to_wrapping_button:
		_go_to_wrapping_button.visible = true
