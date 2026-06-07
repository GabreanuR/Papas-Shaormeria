extends Control

const LOADING_SCENE: String = "res://scenes/menus/loading_screen.tscn"
const MAX_SHOP_NAME_LENGTH: int = 20
const CustomerHistoryScript = preload("res://scripts/ai/customer_history.gd")


@export var menu_music: AudioStream

var _screen_center: Vector2
var _current_slot_id: int = -1
var _is_overwriting: bool = false
var _is_deleting: bool = false

@onready var _button_container: Control = $MainGroup
@onready var _saves_menu: Control = $SavesMenu
@onready var _settings_menu: Control = $SettingsMenu
@onready var _credits_menu: Control = $CreditsMenu
@onready var _shutter: CanvasLayer = $MetalShutter
@onready var _camera: Camera2D = $Camera2D
@onready var _action_popup: Control = $ActionPopup

@onready var _btn_new_game: TextureButton = %NewGameButton
@onready var _btn_load_game: TextureButton = %LoadGameButton
@onready var _btn_settings: TextureButton = %SettingsButton
@onready var _btn_credits: TextureButton = %CreditsButton
@onready var _btn_quit: TextureButton = %QuitButton

func _ready() -> void:
	if menu_music:
		AudioManager.play_music(menu_music, 1.5)

	_screen_center = get_viewport_rect().size / 2.0
	_camera.position = _screen_center

	_connect_signals()

func _connect_signals() -> void:
	# Main Menu Buttons
	_btn_new_game.pressed.connect(_on_new_game_pressed)
	_btn_load_game.pressed.connect(_on_load_game_pressed)
	_btn_settings.pressed.connect(_on_settings_pressed)
	_btn_credits.pressed.connect(_on_credits_pressed)
	_btn_quit.pressed.connect(_on_quit_pressed)

	# Saves Menu
	_saves_menu.closed.connect(_on_saves_closed)
	_saves_menu.request_new.connect(_on_saves_request_new)
	_saves_menu.request_load.connect(_on_saves_request_load)
	_saves_menu.request_delete.connect(_on_saves_request_delete)

	# Secondary UI
	_settings_menu.closed.connect(_on_settings_closed)
	_credits_menu.back_requested.connect(_on_credits_closed)

	# Action Pop-up
	_action_popup.action_confirmed.connect(_on_popup_action_confirmed)
	_action_popup.input_confirmed.connect(_on_popup_input_confirmed)
	_action_popup.cancelled.connect(_on_popup_cancelled)

func _toggle_shop_lights(turning_off: bool) -> void:
	var all_lights: Array[Node] = get_tree().get_nodes_in_group("shop_lights")
	for light in all_lights:
		if turning_off:
			if light.has_method("turn_off"):
				light.turn_off()
		else:
			if light.has_method("turn_on"):
				light.turn_on()

func _start_new_game(save_path: String, shop_name: String) -> void:
	var data = Global.get_default_save_data(shop_name)

	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		push_error("Critical Error: Could not create save file at '%s'." % save_path)
		return

	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	CustomerHistoryScript.set_active_slot(_current_slot_id)
	CustomerHistoryScript.reset_history_for_slot(_current_slot_id)

	Global.load_save_data(_current_slot_id, data)
	_do_transition()
	

func _load_game(save_path: String) -> void:
	if not FileAccess.file_exists(save_path):
		push_error("Error: Attempted to load a non-existent file at '%s'." % save_path)
		return

	var file := FileAccess.open(save_path, FileAccess.READ)
	if not file:
		push_error("Error: Could not open save file at '%s'." % save_path)
		return

	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(content) != OK:
		push_error("Error: Save file at '%s' contains invalid JSON." % save_path)
		return

	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Error: Save file at '%s' does not contain a valid Dictionary." % save_path)
		return

	CustomerHistoryScript.set_active_slot(_current_slot_id)

	Global.load_save_data(_current_slot_id, data)
	_do_transition()
	
## Hides the menu UI, stops music, and loads the next scene.
func _do_transition() -> void:
	_saves_menu.hide()
	_button_container.hide()
	AudioManager.stop_music(1.0)

	var err := get_tree().change_scene_to_file(LOADING_SCENE)
	if err != OK:
		push_error("Critical Error: Could not load '%s'. Error code: %d" % [LOADING_SCENE, err])

func _is_name_duplicate(new_name: String, ignore_slot_id: int) -> bool:
	for i in range(1, Global.MAX_SAVE_SLOTS + 1):
		if i == ignore_slot_id:
			continue

		var path: String = Global.SAVE_FILE_TEMPLATE % i
		if FileAccess.file_exists(path):
			if Global.get_shop_name_from_file(path).to_lower() == new_name.to_lower():
				return true

	return false

# --- Main Menu Buttons ---
func _on_new_game_pressed() -> void:
	_button_container.hide()
	_toggle_shop_lights(true)
	_saves_menu.open_menu("new")

func _on_load_game_pressed() -> void:
	_button_container.hide()
	_toggle_shop_lights(true)
	_saves_menu.open_menu("load")

func _on_settings_pressed() -> void:
	_button_container.hide()
	_toggle_shop_lights(true)
	_settings_menu.open_settings()

func _on_credits_pressed() -> void:
	_button_container.hide()
	_toggle_shop_lights(true)
	_credits_menu.play_credits()

func _on_quit_pressed() -> void:
	_button_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	AudioManager.stop_music(0.5)

	var tween := create_tween()
	tween.set_parallel(true)

	_toggle_shop_lights(true)

	tween.tween_property(_camera, "zoom", Vector2(0.97, 0.97), 2.5) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)

	_shutter.close_shutter()

	await _shutter.shutter_closed
	get_tree().quit()

# --- Sub-Menu Signals ---
func _on_saves_closed() -> void:
	_button_container.show()
	await _saves_menu.overlay.fade_out_finished
	_toggle_shop_lights(false)

func _on_settings_closed() -> void:
	_button_container.show()
	await _settings_menu.overlay.fade_out_finished
	_toggle_shop_lights(false)

func _on_credits_closed() -> void:
	_button_container.show()
	await _credits_menu.overlay.fade_out_finished
	_toggle_shop_lights(false)

# --- Save Slot Interactions ---
func _on_saves_request_new(slot_id: int, is_filled: bool) -> void:
	_current_slot_id = slot_id
	_is_deleting = false

	if is_filled:
		_is_overwriting = true
		_action_popup.ask_confirmation("Overwrite old save?", "Overwrite")
	else:
		_is_overwriting = false
		_action_popup.ask_input("Name your shop:", "Start game")

func _on_saves_request_load(slot_id: int) -> void:
	_current_slot_id = slot_id
	_load_game(Global.SAVE_FILE_TEMPLATE % slot_id)

func _on_saves_request_delete(slot_id: int) -> void:
	_current_slot_id = slot_id
	_is_deleting = true
	_is_overwriting = false
	_action_popup.ask_confirmation("Are you sure?", "Yes, delete")

# --- Action Popup Responses ---
func _on_popup_action_confirmed() -> void:
	var save_path: String = Global.SAVE_FILE_TEMPLATE % _current_slot_id

	if _is_deleting:
		if FileAccess.file_exists(save_path):
			DirAccess.remove_absolute(save_path)
		_is_deleting = false
		_saves_menu.refresh_display()

	elif _is_overwriting:
		_is_overwriting = false
		_action_popup.ask_input("Name your new shop:", "Start game")

func _on_popup_input_confirmed(shop_name: String) -> void:
	var save_path: String = Global.SAVE_FILE_TEMPLATE % _current_slot_id

	if shop_name.is_empty():
		shop_name = "Shop " + str(_current_slot_id)

	if shop_name.length() > MAX_SHOP_NAME_LENGTH:
		shop_name = shop_name.left(MAX_SHOP_NAME_LENGTH)

	if _is_name_duplicate(shop_name, _current_slot_id):
		_action_popup.show_error("Name already exists!")
		return

	_action_popup.hide()
	_start_new_game(save_path, shop_name)

func _on_popup_cancelled() -> void:
	_is_deleting = false
	_is_overwriting = false
