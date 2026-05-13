extends Control

# ---------------------------------------------------------
# 1. SIGNALS (What does this script shout to other scenes?)
# ---------------------------------------------------------

# ---------------------------------------------------------
# 2. ENUMS AND CONSTANTS (Fixed values)
# ---------------------------------------------------------
const SAVE_FILE_TEMPLATE = "user://save_slot_%d.json"
const LOADING_SCENE = "res://scenes/menus/loading_screen.tscn"

# ---------------------------------------------------------
# 3. EXPORTED VARIABLES (Those that appear in the right-side Editor Inspector)
# ---------------------------------------------------------
@export var menu_music: AudioStream

# ---------------------------------------------------------
# 4. PUBLIC VARIABLES (Can be read/modified by other scripts)
# ---------------------------------------------------------

# ---------------------------------------------------------
# 5. PRIVATE VARIABLES (Prefixed with "_"; used only inside this script)
# ---------------------------------------------------------
var _menu_mode: String = "" # Expected values: "new" or "load"
var _screen_center: Vector2

var _current_slot_id: int = -1
var _is_overwriting: bool = false
var _is_deleting: bool = false
# ---------------------------------------------------------
# 6. ONREADY VARIABLES (Links to the UI / Node Tree)
# ---------------------------------------------------------
@onready var button_container: Control = $MainGroup
@onready var saves_menu = $SavesMenu
@onready var settings_menu: Control = $SettingsMenu
@onready var credits_menu: Control = $CreditsMenu
@onready var shutter: CanvasLayer = $MetalShutter
@onready var camera: Camera2D = $Camera2D
@onready var action_popup: Control = $ActionPopup

# ---------------------------------------------------------
# 7. GODOT ENGINE FUNCTIONS (The built-in ones)
# ---------------------------------------------------------
func _ready() -> void:
	if menu_music:
		AudioManager.play_music(menu_music, 1.5)
	
	_screen_center = get_viewport_rect().size / 2.0
	camera.position = _screen_center
	
	_connect_signals()

# ---------------------------------------------------------
# 8. PUBLIC FUNCTIONS (Called by you from other scripts)
# ---------------------------------------------------------

# ---------------------------------------------------------
# 9. PRIVATE FUNCTIONS (Prefixed with "_", used only internally here)
# ---------------------------------------------------------
func _connect_signals() -> void:
	# Main Menu Buttons
	button_container.get_node("NewGameButton").pressed.connect(_on_new_game_pressed)
	button_container.get_node("LoadGameButton").pressed.connect(_on_load_game_pressed)
	button_container.get_node("SettingsButton").pressed.connect(_on_settings_pressed)
	button_container.get_node("CreditsButton").pressed.connect(_on_credits_pressed)
	button_container.get_node("QuitButton").pressed.connect(_on_quit_pressed)
	
	saves_menu.closed.connect(_on_saves_closed)
	saves_menu.request_new.connect(_on_saves_request_new)
	saves_menu.request_load.connect(_on_saves_request_load)
	saves_menu.request_delete.connect(_on_saves_request_delete)
	
	# Secondary UI Buttons
	if not settings_menu.closed.is_connected(_on_settings_closed):
		settings_menu.closed.connect(_on_settings_closed)
	credits_menu.back_requested.connect(_on_credits_closed)
	
	# Action Pop-up
	action_popup.action_confirmed.connect(_on_popup_action_confirmed)
	action_popup.input_confirmed.connect(_on_popup_input_confirmed)
	action_popup.cancelled.connect(func():
		_is_deleting = false
		_is_overwriting = false
	)
	# "Juice" hover effects for main buttons
	for button in button_container.get_children():
		if button is BaseButton: 
			button.mouse_entered.connect(_on_button_hover.bind(button))
			button.mouse_exited.connect(_on_button_unhover.bind(button))

func _fade_shop_lights(tween: Tween, turning_off: bool) -> void:
	var all_lights: Array[Node] = get_tree().get_nodes_in_group("shop_lights")
	
	for light in all_lights:
		# Safety check: ne asigurăm că lumina are scriptul nostru atașat
		if light.has_method("fade_out"):
			if turning_off:
				light.fade_out(tween, 0.4)
			else:
				light.fade_in(tween, 0.6)

func _resume_lights_processing() -> void:
	var all_lights: Array[Node] = get_tree().get_nodes_in_group("shop_lights")
	
	for light in all_lights:
		if light.has_method("resume_flicker"):
			light.resume_flicker()

# --- 1. OPEN / CLOSE LOGIC ---
func _on_new_game_pressed() -> void:
	button_container.hide()
	var tween := create_tween()
	_fade_shop_lights(tween, true)
	saves_menu.open_menu("new")

func _on_load_game_pressed() -> void:
	button_container.hide()
	var tween := create_tween()
	_fade_shop_lights(tween, true)
	saves_menu.open_menu("load")

func _on_saves_closed() -> void:
	button_container.show()
	var tween := create_tween()
	_fade_shop_lights(tween, false)
	tween.chain().tween_callback(_resume_lights_processing)

# --- 2. SIGNAL ROUTING TO ACTION POPUP ---
func _on_saves_request_new(slot_id: int, is_filled: bool) -> void:
	_current_slot_id = slot_id
	_is_deleting = false
	
	if is_filled:
		_is_overwriting = true
		action_popup.ask_confirmation("Overwrite old save?", "Overwrite")
	else:
		_is_overwriting = false
		action_popup.ask_input("Name your shop:", "Start game")

func _on_saves_request_load(slot_id: int) -> void:
	_load_game(SAVE_FILE_TEMPLATE % slot_id)

func _on_saves_request_delete(slot_id: int) -> void:
	_current_slot_id = slot_id
	_is_deleting = true
	_is_overwriting = false
	action_popup.ask_confirmation("Are you sure?", "Yes, delete")

func _get_default_save_data(shop_name: String) -> Dictionary:
	return {
		"day": 1,
		"money": 150.0,
		"reputation": 0,
		"inventory": { "meat_kg": 10.0, "pita_bread": 20, "garlic_sauce": 15, "spicy_sauce": 15 },
		"unlocked_upgrades": [],
		"shop_name": shop_name 
	}

func _start_new_game(save_path: String, shop_name: String) -> void:
	var data := _get_default_save_data(shop_name)
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	
	if file:
		var json_string := JSON.stringify(data, "\t")
		file.store_string(json_string)
		file.close()
		_transition_to_game()
	else:
		push_error("Critical Error: Could not create save file at ", save_path)

func _load_game(save_path: String) -> void:
	if FileAccess.file_exists(save_path):
		_transition_to_game()
	else:
		push_error("Error: Attempted to load a non-existent file!")

func _transition_to_game() -> void:
	saves_menu.hide()
	button_container.hide()
	
	AudioManager.stop_music(1.0)
	
	_on_transition_done()

func _get_shop_name_from_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return "Error Reading"
		
	var content := file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(content)
	
	# Verificăm dacă data este un dicționar valid și are cheia salvată anterior
	if data is Dictionary and data.has("shop_name"):
		return str(data["shop_name"])
			
	return "No Name Found"
	
func _is_name_duplicate(new_name: String, ignore_slot_id: int) -> bool:
	for i in range(1, 4):
		if i == ignore_slot_id:
			continue 
			
		var path: String = SAVE_FILE_TEMPLATE % i
		if FileAccess.file_exists(path):
			var existing_name: String = _get_shop_name_from_file(path)
			if existing_name.to_lower() == new_name.to_lower():
				return true
				
	return false

# ---------------------------------------------------------
# 10. SIGNAL CALLBACKS (What happens when buttons/timers trigger)
# ---------------------------------------------------------
func _on_button_hover(btn: BaseButton) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	
	btn.pivot_offset = btn.size / 2.0
	
	# Scale up by 5% and slightly darken
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(btn, "modulate", Color(0.8, 0.8, 0.8, 1.0), 0.1)

func _on_button_unhover(btn: BaseButton) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	
	# Restore original scale and brightness
	tween.tween_property(btn, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(btn, "modulate", Color.WHITE, 0.1)

func _on_settings_pressed() -> void:
	button_container.hide()

	var tween := create_tween()
	_fade_shop_lights(tween, true)
	
	settings_menu.open_settings()

func _on_settings_closed() -> void:
	# 1. Arătăm butoanele INSTANTANEU, chiar când începe închiderea
	button_container.show()
	
	# 2. Pornim restul efectelor vizuale în fundal
	var tween := create_tween()
	_fade_shop_lights(tween, false)
	
	# 3. La finalul tween-ului, doar repornim logica de lumini (fără să mai ascundem UI-ul)
	tween.chain().tween_callback(_resume_lights_processing)
	
func _on_credits_pressed() -> void:
	button_container.hide()
	
	var tween := create_tween()
	_fade_shop_lights(tween, true)
	
	credits_menu.play_credits()
		
func _on_credits_closed() -> void:
	button_container.show()
	
	var tween := create_tween()
	_fade_shop_lights(tween, false)
	tween.chain().tween_callback(_resume_lights_processing)

func _on_quit_pressed() -> void:
	# Disable user input
	button_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	AudioManager.stop_music(0.5)
	
	var tween := create_tween()
	tween.set_parallel(true)
	
	_fade_shop_lights(tween, true)
	
	tween.tween_property(camera, "zoom", Vector2(0.97, 0.97), 2.5) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)
	
	shutter.close_shutter()
	
	await shutter.shutter_closed
	get_tree().quit()

func _on_slot_clicked(slot_id: int, is_filled: bool) -> void:
	_current_slot_id = slot_id
	_is_deleting = false
	
	if _menu_mode == "new":
		if is_filled:
			_is_overwriting = true
			action_popup.ask_confirmation("Overwrite old save?", "Overwrite")
		else:
			_is_overwriting = false
			action_popup.ask_input("Name your shop:", "Start game")
			
	elif _menu_mode == "load" and is_filled:
		_load_game(SAVE_FILE_TEMPLATE % slot_id)

# 1. Când jucătorul a zis "Da" la ștergere sau suprascriere
func _on_popup_action_confirmed() -> void:
	var save_path: String = SAVE_FILE_TEMPLATE % _current_slot_id
	
	if _is_deleting:
		if FileAccess.file_exists(save_path):
			DirAccess.remove_absolute(save_path)
		_is_deleting = false
		saves_menu.refresh_display()
		
	elif _is_overwriting:
		_is_overwriting = false
		action_popup.ask_input("Name your new shop:", "Start game")

# 2. Când jucătorul a dat Submit la numele magazinului
func _on_popup_input_confirmed(shop_name: String) -> void:
	var save_path: String = SAVE_FILE_TEMPLATE % _current_slot_id
	
	if shop_name.is_empty():
		shop_name = "Shop " + str(_current_slot_id)
		
	if shop_name.length() > 20:
		shop_name = shop_name.left(20)
		
	if _is_name_duplicate(shop_name, _current_slot_id):
		action_popup.show_error("Numele există deja! Alege altul.")
		return
		
	action_popup.hide()
	_start_new_game(save_path, shop_name)

func _on_transition_done() -> void:
	var err := get_tree().change_scene_to_file(LOADING_SCENE)
	if err != OK:
		push_error("Critical Error: Could not load '%s'. Error code: %d" % [LOADING_SCENE, err])

func _on_delete_request(slot_id: int) -> void:
	_current_slot_id = slot_id
	_is_deleting = true
	_is_overwriting = false
	
	action_popup.ask_confirmation("Are you sure?", "Yes, delete")
