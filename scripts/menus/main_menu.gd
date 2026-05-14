extends Control

const SAVE_FILE_TEMPLATE = "user://save_slot_%d.json"
const LOADING_SCENE = "res://scenes/menus/loading_screen.tscn"

@export var menu_music: AudioStream

var _menu_mode: String = "" # Expected values: "new" or "load"
var _screen_center: Vector2

var _current_slot_id: int = -1
var _is_overwriting: bool = false
var _is_deleting: bool = false

@onready var button_container: Control = $MainGroup
@onready var saves_menu = $SavesMenu
@onready var settings_menu: Control = $SettingsMenu
@onready var credits_menu: Control = $CreditsMenu
@onready var shutter: CanvasLayer = $MetalShutter
@onready var camera: Camera2D = $Camera2D
@onready var action_popup: Control = $ActionPopup

func _ready() -> void:
	if menu_music:
		AudioManager.play_music(menu_music, 1.5)
	
	_screen_center = get_viewport_rect().size / 2.0
	camera.position = _screen_center
	
	_connect_signals()

func _connect_signals() -> void:
	# Main Menu Buttons
	button_container.get_node("NewGameButton").pressed.connect(_on_new_game_pressed)
	button_container.get_node("LoadGameButton").pressed.connect(_on_load_game_pressed)
	button_container.get_node("SettingsButton").pressed.connect(_on_settings_pressed)
	button_container.get_node("CreditsButton").pressed.connect(_on_credits_pressed)
	button_container.get_node("QuitButton").pressed.connect(_on_quit_pressed)
	
	# Saves Menu
	saves_menu.closed.connect(_on_saves_closed)
	saves_menu.request_new.connect(_on_saves_request_new)
	saves_menu.request_load.connect(_on_saves_request_load)
	saves_menu.request_delete.connect(_on_saves_request_delete)
	
	# Secondary UI Buttons
	settings_menu.closed.connect(_on_settings_closed)
	credits_menu.back_requested.connect(_on_credits_closed)
	
	# Action Pop-up
	action_popup.action_confirmed.connect(_on_popup_action_confirmed)
	action_popup.input_confirmed.connect(_on_popup_input_confirmed)
	action_popup.cancelled.connect(_on_popup_cancelled)

func _toggle_shop_lights(turning_off: bool) -> void:
	var all_lights: Array[Node] = get_tree().get_nodes_in_group("shop_lights")
	
	for light in all_lights:
		# Safety check: ensure the light has our script attached
		if turning_off:
			if light.has_method("turn_off"):
				light.turn_off()
		else:
			if light.has_method("turn_on"):
				light.turn_on()

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
	if not FileAccess.file_exists(path):
		return "Error Reading"
		
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return "Error Reading"
		
	var content := file.get_as_text()
	file.close()
	
	# Future-proof JSON parsing
	var json := JSON.new()
	if json.parse(content) == OK:
		var data = json.get_data()
		if typeof(data) == TYPE_DICTIONARY and data.has("shop_name"):
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

# --- Main Menu Buttons ---
func _on_new_game_pressed() -> void:
	button_container.hide()
	_toggle_shop_lights(true)
	saves_menu.open_menu("new")

func _on_load_game_pressed() -> void:
	button_container.hide()
	_toggle_shop_lights(true)
	saves_menu.open_menu("load")

func _on_settings_pressed() -> void:
	button_container.hide()
	_toggle_shop_lights(true)
	settings_menu.open_settings()

func _on_credits_pressed() -> void:
	button_container.hide()
	_toggle_shop_lights(true)
	credits_menu.play_credits()

func _on_quit_pressed() -> void:
	# Disable user input
	button_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	AudioManager.stop_music(0.5)
	
	var tween := create_tween()
	tween.set_parallel(true)
	
	_toggle_shop_lights(true)
	
	tween.tween_property(camera, "zoom", Vector2(0.97, 0.97), 2.5) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)
	
	shutter.close_shutter()
	
	await shutter.shutter_closed
	get_tree().quit()

# --- Sub-Menu Signals ---
func _on_saves_closed() -> void:
	button_container.show()
	await saves_menu.overlay.fade_out_finished
	_toggle_shop_lights(false)

func _on_settings_closed() -> void:
	# 1. Show buttons INSTANTLY right when closing starts
	button_container.show()
	
	# 2. Wait for the menu to disappear completely before turning on lights
	await settings_menu.overlay.fade_out_finished
	_toggle_shop_lights(false)
	
func _on_credits_closed() -> void:
	button_container.show()
	
	# Wait for the menu to disappear completely
	await credits_menu.overlay.fade_out_finished
	_toggle_shop_lights(false)

# --- Save Slot Interactions ---
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

# --- Action Popup Responses ---
# 1. When the user confirmed deletion or overwrite
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

# 2. When the user submitted the shop name
func _on_popup_input_confirmed(shop_name: String) -> void:
	var save_path: String = SAVE_FILE_TEMPLATE % _current_slot_id
	
	if shop_name.is_empty():
		shop_name = "Shop " + str(_current_slot_id)
		
	if shop_name.length() > 20:
		shop_name = shop_name.left(20)
		
	if _is_name_duplicate(shop_name, _current_slot_id):
		action_popup.show_error("Name already exists! Choose another.")
		return
		
	action_popup.hide()
	_start_new_game(save_path, shop_name)

func _on_popup_cancelled() -> void:
	_is_deleting = false
	_is_overwriting = false

# --- Transitions ---
func _on_transition_done() -> void:
	var err := get_tree().change_scene_to_file(LOADING_SCENE)
	if err != OK:
		push_error("Critical Error: Could not load '%s'. Error code: %d" % [LOADING_SCENE, err])
