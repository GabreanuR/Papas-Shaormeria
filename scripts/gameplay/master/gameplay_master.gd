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
var profit_ziua_curenta: float = 0.0

@export var gameplay_music: AudioStream

static func _new_pita_state() -> Dictionary:
	return {
		"lipie_quality": "ready",
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
	var score = current_pita_state["total_score"]

	if Global.is_arcade_mode:
		Global.register_arcade_order(score)
		completed_pitas.append(current_pita_state.duplicate(true))
		current_pita_state = _new_pita_state()
		return

	# 1. Numărăm dacă șaorma e "Perfectă" 
	if current_pita_state["total_score"] == 100:
		Global.daily_stats["perfect_orders"] += 1
		
		if Global.daily_stats["perfect_orders"] >= 5:
			Global.unlock_achievement("perfectionist")
	
	# 2. Numărăm clientul (fiecare salvare e un client servit)
	Global.daily_stats["customers_served"] += 1
	
	# 🏆 DECLANȘATOARE REALIZĂRI (Achievements Core Triggers)
	Global.unlock_achievement("first_bite")
	
	score = current_pita_state["total_score"]

	if score == 0:
		Global.unlock_achievement("kitchen_disaster")
	elif score < 50:
		Global.unlock_achievement("oops")
		
	if Global.daily_stats["customers_served"] >= 20:
		Global.unlock_achievement("crowd_pleaser")
		
	if Global.current_save["money"] >= 500.0:
		Global.unlock_achievement("rolling_in_dough")
	
	# 3. Adăugăm la istoric
	completed_pitas.append(current_pita_state.duplicate(true))
	current_pita_state = _new_pita_state()

var completed_pitas: Array[Dictionary] = []
var is_current_pita_wrapping := false
# ---------------------------------------------------------
# 5. PRIVATE VARIABLES
# ---------------------------------------------------------
var _assembly_camera: Camera2D
var _sauce_finish_timer: Timer
var _go_to_sauces_button: Button
var _go_to_wrapping_button: Button
var _profit_label: Label

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

	if gameplay_music:
		AudioManager.play_music(gameplay_music, 1.5)

	# Fix: Mutăm TopBar-ul în CanvasLayer ca să rămână mereu pe ecran, indiferent unde se duce camera!
	var top_bar = get_node_or_null("TopBar")
	if top_bar and $CanvasLayer:
		top_bar.reparent($CanvasLayer)
		if "mode" in top_bar:
			top_bar.mode = top_bar.BarMode.GAMEPLAY
			if top_bar.has_method("_setup_gameplay_mode"):
				top_bar._setup_gameplay_mode()
		
	var wrap_area = _wrapping_station.find_child("WrapGestureArea", true, false)
	if wrap_area:
		wrap_area.wrap_step_changed.connect(_on_wrapping_started)

	_create_assembly_buttons()
	_create_sauce_finish_timer()
	
	_profit_label = _gaseste_label_profit(self)
	
	if not Global.is_arcade_mode and _profit_label:
		_profit_label.text = "Profit: $ 0.00"
	
	if not Global.day_ended.is_connected(_on_day_ended):
		Global.day_ended.connect(_on_day_ended)

	# Start on the order station by default.
	_go_to_order()
	
	if _order_station:
		actualizeaza_text_clienti(_order_station.clienti_serviti, _order_station.total_clienti_zi)

func _process(_delta: float) -> void:
	# Transformăm eticheta de Profit în Timer dacă suntem în Arcade Mode!
	if Global.is_arcade_mode and _profit_label:
		var t = int(Global.day_time_left)
		_profit_label.text = "Time Left: %02d:%02d" % [t / 60, t % 60]

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
	
	if current_pita_state.get("meat_type", "") == "":
		var queue: Array = get_meta("prepared_shaormas_queue", [])
		if queue.size() > 0:
			var prepared_data: Dictionary = queue.pop_front()
			set_meta("prepared_shaormas_queue", queue)

			current_pita_state = _new_pita_state()
			current_pita_state["lipie_quality"] = prepared_data.get("lipie_quality", "ready")
			current_pita_state["meat_type"] = prepared_data.get("meat_type", "")
			current_pita_state["is_cut"] = true
			current_pita_state["scores"]["cutting"] = prepared_data.get("cutting_score", 0)

			var lipie = _assembly_station.find_child("Lipie", true, false)
			if lipie and lipie.has_method("update_from_cutting"):
				lipie.update_from_cutting(prepared_data)
				apply_lipie_quality_visual(lipie, current_pita_state.get("lipie_quality", "ready"))

	var are_carne = current_pita_state.get("meat_type", "") != ""
	
	var lipie_container = _assembly_station.find_child("LipieContainer", true, false)
	if lipie_container:
		lipie_container.visible = (are_carne and not is_current_pita_wrapping)
	
	var lipie_sprite = _assembly_station.find_child("Lipie", true, false)

	if lipie_container and lipie_sprite:
		var offset = LIPIE_INGREDIENTS_POS - lipie_sprite.global_position
		lipie_container.global_position += offset

	if _go_to_sauces_button:
		_go_to_sauces_button.visible = true

	if _go_to_wrapping_button:
		_go_to_wrapping_button.visible = false

func apply_lipie_quality_visual(lipie_node: Node, lipie_quality: String) -> void:
	if lipie_node == null:
		return

	var color := Color(1, 1, 1, 1)

	if lipie_quality == "burned":
		color = Color(0.45, 0.25, 0.12, 1.0)

	if lipie_node is CanvasItem:
		(lipie_node as CanvasItem).modulate = color


func _go_to_wrapping() -> void:
	if _assembly_camera:
		_assembly_camera.enabled = false

	finish_sauce_mode()

	var lipie_container = _assembly_station.find_child("LipieContainer", true, false)

	if lipie_container:
		var lipie_orig = lipie_container.find_child("Lipie", true, false)
		if lipie_orig:
			current_pita_state["ingrediente_salvate"] = lipie_orig.ingrediente_puse.duplicate()
			current_pita_state["scor_sos_salvat"] = lipie_orig.calculeaza_scor_sos()

	if lipie_container and _wrapping_station.has_method("receive_pita_from_assembly"):
		if current_pita_state.get("meat_type", "") != "":
			var lipie_copy = lipie_container.duplicate(
				Node.DUPLICATE_SIGNALS | Node.DUPLICATE_GROUPS | Node.DUPLICATE_SCRIPTS
			)
			_wrapping_station.receive_pita_from_assembly(lipie_copy, current_pita_state.duplicate(true))
		else:
			_wrapping_station.receive_pita_from_assembly(null, current_pita_state.duplicate(true))

	_show_only(_wrapping_station)
	_activate_camera_for(_wrapping_station)

# ---------------------------------------------------------
# 10. SIGNAL CALLBACKS
# ---------------------------------------------------------
func _on_day_ended() -> void:
	AudioManager.stop_music(1.0)
	
	if Global.is_arcade_mode:
		# Ieșim din Arcade Mode direct în dimineața normală, FĂRĂ BANI SALVAȚI și FĂRĂ NOAPTE
		Global.is_arcade_mode = false
		Global.is_night = false
		get_tree().change_scene_to_file("res://scenes/day_management/day_transition.tscn")
	else:
		# Logica originală pentru Campania normală
		Global.daily_earnings = profit_ziua_curenta
		Global.daily_stats["tips_earned"] = profit_ziua_curenta
		
		Global.end_day_and_save_earnings()
		Global.is_night = true
		
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


func _on_wrapping_started(step_index: int) -> void:
	if step_index >= 0:
		is_current_pita_wrapping = true
		var lipie_container = _assembly_station.find_child("LipieContainer", true, false)
		if lipie_container:
			lipie_container.visible = false


func arata_evaluarea_la_client(nota_finala: int) -> void:
	# 1. Trecem fizic pe ecranul stației de comenzi
	_go_to_order()
	
	# 2. Îi spunem stației să pună fundalul de tejghea (close-up)
	if _order_station and _order_station.has_method("pregateste_tejgheaua_pentru_evaluare"):
		_order_station.pregateste_tejgheaua_pentru_evaluare()
		
	# 3. Căutăm pozele cu lipia și sucul la Wrapping Station
	var wrap_station = get_tree().get_first_node_in_group("wrapping_station")
	var t_lipie = null
	var t_suc = null
	
	if wrap_station != null:
		if "carried_final_texture" in wrap_station:
			t_lipie = wrap_station.carried_final_texture
		if "selected_drink_texture" in wrap_station:
			t_suc = wrap_station.selected_drink_texture
			
	# Trimitem absolut tot (nota, lipia, sucul) spre Order Station!
	if _order_station and _order_station.has_method("arata_evaluare_finala"):
		_order_station.arata_evaluare_finala(nota_finala, t_lipie, t_suc)

func seteaza_stare_butoane_statii(active: bool) -> void:
	if _btn_cutting:
		_btn_cutting.disabled = not active
	if _btn_assembly:
		_btn_assembly.disabled = not active
	if _btn_wrapping:
		_btn_wrapping.disabled = not active

# Funcție care primește bacșișul și actualizează textul
func adauga_bacsis(suma: float) -> void:
	profit_ziua_curenta += suma
	
	# Căutăm label-ul de profit oriunde ar fi el în scenă
	# (Caută nodurile care conțin cuvântul "Profit")
	var label_profit = _gaseste_label_profit(self)
	if label_profit:
		# Formatăm textul cu 2 zecimale (ex: 4.50)
		label_profit.text = "Profit: $ %.2f" % profit_ziua_curenta

# Funcție utilitară pentru a găsi Label-ul din TopBar
func _gaseste_label_profit(nod: Node) -> Label:
	if nod is Label and nod.text.begins_with("Profit:"):
		return nod
	for copil in nod.get_children():
		var gasit = _gaseste_label_profit(copil)
		if gasit:
			return gasit
	return null


func actualizeaza_text_clienti(serviti: int, total: int) -> void:
	# Știm că TopBar a fost mutat în CanvasLayer în _ready()
	var top_bar = $CanvasLayer.get_node_or_null("TopBar")
	if top_bar and top_bar.has_method("update_customer_counter"):
		top_bar.update_customer_counter(serviti, total)
		
		
