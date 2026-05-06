extends Control

# ---------------------------------------------------------
# 1. SIGNALS (What does this script shout to other scenes?)
# ---------------------------------------------------------

# ---------------------------------------------------------
# 2. ENUMS AND CONSTANTS (Fixed values)
# ---------------------------------------------------------
const SAVE_FILE_TEMPLATE = "user://save_slot_%d.json"
const PARALLAX_MULTIPLIERS = [0.005, 0.01, 0.015, 0.02, 0.015]
const LOADING_SCENE = "res://scenes/menus/loading_screen.tscn"

# ---------------------------------------------------------
# 3. EXPORTED VARIABLES (Those that appear in the right-side Editor Inspector)
# ---------------------------------------------------------
@export var menu_music: AudioStream
@export var shutter_sfx: AudioStream

# ---------------------------------------------------------
# 4. PUBLIC VARIABLES (Can be read/modified by other scripts)
# ---------------------------------------------------------
var menu_mode: String = "" # Expected values: "new" or "load"
var screen_center: Vector2
var base_positions: Array[Vector2] = []

var current_slot_id: int = -1
var is_overwriting: bool = false

var tex_empty_normal = preload("res://assets/graphics/ui/slot_normal.png")
var tex_empty_hover = preload("res://assets/graphics/ui/slot_hover.png")
var tex_filled_normal = preload("res://assets/graphics/ui/slot_filled_normal.png")
var tex_filled_hover = preload("res://assets/graphics/ui/slot_filled_hover.png")

var is_deleting: bool = false # Stare nouă pentru pop-up

# ---------------------------------------------------------
# 5. PRIVATE VARIABLES (Prefixed with "_"; used only inside this script)
# ---------------------------------------------------------

# ---------------------------------------------------------
# 6. ONREADY VARIABLES (Links to the UI / Node Tree)
# ---------------------------------------------------------
@onready var parallax_layers = [
	$ParallaxBackground/Layer1_Sky,
	$ParallaxBackground/Layer2_City,
	$ParallaxBackground/Layer3_Shop,
	$ParallaxBackground/Layer4_Name,
	$ParallaxBackground/Layer5_Shaorma
]

@onready var dark_overlay = $DarkOverlay
@onready var receipt_node = $ReceiptNode
@onready var btn_close_credits = $ReceiptNode/BtnCloseCredits

@onready var shutter = $MetalShutter
@onready var button_container = $ParallaxBackground/Layer5_Shaorma/MainGroup

@onready var settings_panel = $SettingsPanel
@onready var btn_close_settings = $SettingsPanel/MarginContainer/VBoxContainer/BtnCloseSettings
@onready var fullscreen_toggle = $SettingsPanel/MarginContainer/VBoxContainer/FullscreenToggleControl/FullscreenToggle
@onready var volume_slider = $SettingsPanel/MarginContainer/VBoxContainer/MasterVolume/HSlider

@onready var saves_panel = $SaveSlotsPanel
@onready var btn_close_saves = $SaveSlotsPanel/MarginContainer/VBoxContainer/BtnCloseSaves
@onready var saves_title = $SaveSlotsPanel/MarginContainer/VBoxContainer/SaveSlotsLabel

@onready var slots = [
	$SaveSlotsPanel/MarginContainer/VBoxContainer/HBoxContainer/Slot1,
	$SaveSlotsPanel/MarginContainer/VBoxContainer/HBoxContainer/Slot2,
	$SaveSlotsPanel/MarginContainer/VBoxContainer/HBoxContainer/Slot3
]

@onready var action_popup = $ActionPopup
@onready var popup_title = $ActionPopup/Panel/MarginContainer/VBoxContainer/PopupTitle
@onready var popup_input = $ActionPopup/Panel/MarginContainer/VBoxContainer/PopupInput
@onready var btn_confirm = $ActionPopup/Panel/MarginContainer/VBoxContainer/HBoxContainer/BtnConfirm
@onready var btn_cancel = $ActionPopup/Panel/MarginContainer/VBoxContainer/HBoxContainer/BtnCancel

@onready var delete_btns = [
	$SaveSlotsPanel/MarginContainer/VBoxContainer/HBoxContainer/Slot1/DeleteBtn1,
	$SaveSlotsPanel/MarginContainer/VBoxContainer/HBoxContainer/Slot2/DeleteBtn2,
	$SaveSlotsPanel/MarginContainer/VBoxContainer/HBoxContainer/Slot3/DeleteBtn3
]

@onready var slot_labels = [
	$SaveSlotsPanel/MarginContainer/VBoxContainer/HBoxContainer/Slot1/SlotLabel1,
	$SaveSlotsPanel/MarginContainer/VBoxContainer/HBoxContainer/Slot2/SlotLabel2,
	$SaveSlotsPanel/MarginContainer/VBoxContainer/HBoxContainer/Slot3/SlotLabel3
]

# ---------------------------------------------------------
# 7. GODOT ENGINE FUNCTIONS (The built-in ones)
# ---------------------------------------------------------
func _ready() -> void:
	if menu_music:
		AudioManager.play_music(menu_music, 1.5)
		
	_update_screen_data()
	
	if not get_viewport().size_changed.is_connected(_update_screen_data):
		get_viewport().size_changed.connect(_update_screen_data)

	$Camera2D.position = screen_center
	
	_connect_signals()
	_initialize_ui_state()

func _process(delta: float) -> void:
	var mouse_pos := get_global_mouse_position()
	var offset := mouse_pos - screen_center
	
	for i in range(parallax_layers.size()):
		var target_position: Vector2 = base_positions[i] - (offset * PARALLAX_MULTIPLIERS[i])
		parallax_layers[i].position = parallax_layers[i].position.lerp(target_position, 5.0 * delta)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		_toggle_fullscreen()

# ---------------------------------------------------------
# 8. PUBLIC FUNCTIONS (Called by you from other scripts)
# ---------------------------------------------------------

# ---------------------------------------------------------
# 9. PRIVATE FUNCTIONS (Prefixed with "_", used only internally here)
# ---------------------------------------------------------
func _refresh_slots() -> void:
	for i in range(slots.size()):
		var slot_btn: Button = slots[i]
		var del_btn: TextureButton = delete_btns[i]
		var name_label: Label = slot_labels[i]
		var slot_id: int = i + 1
		
		var save_path: String = SAVE_FILE_TEMPLATE % slot_id
		var has_save: bool = FileAccess.file_exists(save_path)
		
		slot_btn.text = "" 
		slot_btn.modulate = Color.WHITE
		
		var style_normal := StyleBoxTexture.new()
		var style_hover := StyleBoxTexture.new()
		
		if has_save:
			var full_name: String = _get_shop_name_from_file(save_path)
			
			if full_name.length() > 20:
				name_label.text = full_name.left(17) + "..."
			else:
				name_label.text = full_name
			
			name_label.show() 
			slot_btn.disabled = false
			
			style_normal.texture = tex_filled_normal
			style_hover.texture = tex_filled_hover
			del_btn.visible = (menu_mode == "load")
			
		else:
			del_btn.visible = false
			
			if menu_mode == "load":
				name_label.text = "EMPTY SLOT"
				name_label.show()
				slot_btn.disabled = true
				slot_btn.modulate = Color(0.5, 0.5, 0.5, 0.7)
			else:
				name_label.text = ""
				name_label.hide()
				slot_btn.disabled = false
				slot_btn.modulate = Color.WHITE
				
			style_normal.texture = tex_empty_normal
			style_hover.texture = tex_empty_hover

		slot_btn.add_theme_stylebox_override("normal", style_normal)
		slot_btn.add_theme_stylebox_override("hover", style_hover)
		
		if slot_btn.pressed.is_connected(_on_slot_clicked):
			slot_btn.pressed.disconnect(_on_slot_clicked)
		slot_btn.pressed.connect(_on_slot_clicked.bind(slot_id, has_save))
		
		if not del_btn.pressed.is_connected(_on_delete_request):
			del_btn.pressed.connect(_on_delete_request.bind(slot_id))

func _connect_signals() -> void:
	# Main Menu Buttons
	button_container.get_node("NewGameButton").pressed.connect(_on_new_game_pressed)
	button_container.get_node("LoadGameButton").pressed.connect(_on_load_game_pressed)
	button_container.get_node("SettingsButton").pressed.connect(_on_settings_pressed)
	button_container.get_node("CreditsButton").pressed.connect(_on_credits_pressed)
	button_container.get_node("QuitButton").pressed.connect(_on_quit_pressed)
	
	# Secondary UI Buttons
	btn_close_settings.pressed.connect(_on_close_settings_pressed)
	btn_close_credits.pressed.connect(_on_close_credits_pressed)
	btn_close_saves.pressed.connect(_on_close_saves_pressed)
	
	# Settings Toggles & Sliders
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	volume_slider.value_changed.connect(_on_volume_changed)
	
	# Action Pop-up
	btn_confirm.pressed.connect(_on_popup_confirm_pressed)
	btn_cancel.pressed.connect(func(): 
		action_popup.hide()
		is_deleting = false
		is_overwriting = false
	)
	
	# "Juice" hover effects for main buttons
	for button in button_container.get_children():
		if button is BaseButton: 
			button.mouse_entered.connect(_on_button_hover.bind(button))
			button.mouse_exited.connect(_on_button_unhover.bind(button))

func _initialize_ui_state() -> void:
	# Sync UI toggles with actual engine state
	var is_full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_toggle.button_pressed = is_full
	
	var master_bus_index := AudioServer.get_bus_index("Master")
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus_index))
	
	# Safe initial visual states (hidden or off-screen)
	settings_panel.position.y = -1000
	saves_panel.position.y = -1000
	receipt_node.position.y = 1200
	
	btn_close_credits.scale = Vector2(0.25, 0.25)
	dark_overlay.modulate.a = 0.0
	action_popup.hide()

func _update_screen_data() -> void:
	screen_center = get_viewport_rect().size / 2.0
	base_positions.clear() 
	
	for layer in parallax_layers:
		layer.pivot_offset = layer.size / 2.0
		var base_pos: Vector2 = screen_center - (layer.size / 2.0)
		base_positions.append(base_pos)
		layer.position = base_pos

func _toggle_fullscreen() -> void:
	var current_mode := DisplayServer.window_get_mode()
	var is_full := current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN
	
	if is_full:
		_apply_windowed_mode()
		fullscreen_toggle.set_pressed_no_signal(false)
	else:
		DisplayServer.call_deferred("window_set_mode", DisplayServer.WINDOW_MODE_FULLSCREEN)
		fullscreen_toggle.set_pressed_no_signal(true)

# Helper function to prevent code duplication when exiting fullscreen
func _apply_windowed_mode() -> void:
	# Use call_deferred to prevent input processing crashes
	DisplayServer.call_deferred("window_set_mode", DisplayServer.WINDOW_MODE_WINDOWED)
	
	# Force a smaller resolution to prevent OS auto-maximizing
	var windowed_size := Vector2i(1280, 720)
	DisplayServer.call_deferred("window_set_size", windowed_size)
	
	# Center the newly created window on the monitor
	var current_screen_pos := DisplayServer.screen_get_position()
	var current_screen_size := DisplayServer.screen_get_size()
	var window_pos: Vector2i = current_screen_pos + (current_screen_size / 2) - (windowed_size / 2)
	
	DisplayServer.call_deferred("window_set_position", window_pos)

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

func _open_saves_panel() -> void:
	# Update slot visuals based on existing save files
	_refresh_slots()
	
	button_container.hide()
	var tween := create_tween()
	tween.set_parallel(true)
	
	# Turn off shop lights using the helper function
	_fade_shop_lights(tween, true)
	
	tween.tween_property(dark_overlay, "modulate:a", 0.85, 0.5)
	
	# Explicit Vector2 typing to prevent inference errors
	var target_pos: Vector2 = screen_center - (saves_panel.size / 2.0)
	tween.tween_property(saves_panel, "position", target_pos, 0.7)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

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
		print("File found. Starting transition...")
		_transition_to_game()
	else:
		push_error("Error: Attempted to load a non-existent file!")

func _transition_to_game() -> void:
	saves_panel.hide()
	button_container.hide()
	
	AudioManager.stop_music(1.0)
		
	var tween := create_tween()
	
	tween.tween_property(dark_overlay, "modulate:a", 1.0, 1.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	
	tween.finished.connect(_on_transition_done)

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

func _on_fullscreen_toggled(button_pressed: bool) -> void:
	if button_pressed:
		DisplayServer.call_deferred("window_set_mode", DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		_apply_windowed_mode()

func _on_volume_changed(value: float) -> void:
	var master_bus_index := AudioServer.get_bus_index("Master")
	
	# Prevent static/hissing by fully muting when slider is near zero
	if value <= 0.01:
		AudioServer.set_bus_mute(master_bus_index, true)
	else:
		AudioServer.set_bus_mute(master_bus_index, false)
		# Convert linear UI scale (0.0 - 1.0) to logarithmic Audio dB
		AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value))

func _on_settings_pressed() -> void:
	print("Opening Settings...")
	button_container.hide()
	
	var tween := create_tween()
	tween.set_parallel(true)
	
	_fade_shop_lights(tween, true)
	tween.tween_property(dark_overlay, "modulate:a", 0.85, 0.5)
	
	var target_pos: Vector2 = screen_center - (settings_panel.size / 2.0)
	tween.tween_property(settings_panel, "position", target_pos, 0.7)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

func _on_close_settings_pressed() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	
	_fade_shop_lights(tween, false)
	
	var hidden_pos := Vector2(settings_panel.position.x, -1000)
	tween.tween_property(settings_panel, "position", hidden_pos, 0.6)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)
		
	tween.tween_property(dark_overlay, "modulate:a", 0.0, 0.5)
	
	tween.chain().tween_callback(func(): 
		button_container.show()
		_resume_lights_processing()
	)

func _on_credits_pressed() -> void:
	print("Printing credits receipt...")
	button_container.hide()
	
	var tween := create_tween()
	tween.set_parallel(true)
	
	_fade_shop_lights(tween, true)
	tween.tween_property(dark_overlay, "modulate:a", 0.85, 0.5)
	tween.tween_property(receipt_node, "position:y", -50, 0.8)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
		
func _on_close_credits_pressed() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	
	_fade_shop_lights(tween, false)
	tween.tween_property(receipt_node, "position:y", -1200, 0.6)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)
		
	tween.tween_property(dark_overlay, "modulate:a", 0.0, 0.6)
	
	tween.chain().tween_callback(func():
		button_container.show()
		receipt_node.position.y = 1200
		_resume_lights_processing()
	)

func _on_quit_pressed() -> void:
	print("Closing shop. Zooming out and pulling shutters...")
	
	# Prevent clicking anything else while quitting
	button_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	AudioManager.stop_music(0.5)
	if shutter_sfx:
		AudioManager.play_sfx(shutter_sfx)
	
	var tween := create_tween()
	tween.set_parallel(true)
	
	_fade_shop_lights(tween, true)
	
	tween.tween_property($Camera2D, "zoom", Vector2(0.98, 0.98), 0.7)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(shutter, "position", Vector2(-20, -10), 3.0)\
		.set_trans(Tween.TRANS_QUINT)\
		.set_ease(Tween.EASE_OUT)
		
	tween.chain().tween_callback(func(): get_tree().quit())

func _on_new_game_pressed() -> void:
	menu_mode = "new"
	saves_title.text = "New Game - Pick a slot"
	_open_saves_panel()

func _on_load_game_pressed() -> void:
	menu_mode = "load"
	saves_title.text = "Load Game - Choose a save"
	_open_saves_panel()

func _on_close_saves_pressed() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	
	# Turn shop lights back on using the helper function
	_fade_shop_lights(tween, false)
	
	var hidden_pos := Vector2(saves_panel.position.x, -1000)
	tween.tween_property(saves_panel, "position", hidden_pos, 0.6)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)
		
	tween.tween_property(dark_overlay, "modulate:a", 0.0, 0.5)
	
	tween.chain().tween_callback(func(): 
		button_container.show()
		_resume_lights_processing()
	)

func _on_slot_clicked(slot_id: int, is_filled: bool) -> void:
	current_slot_id = slot_id
	is_deleting = false 
	
	btn_cancel.text = "Cancel"
	
	if menu_mode == "new":
		action_popup.show()
		
		if is_filled:
			is_overwriting = true
			popup_title.text = "Overwrite old save?"
			popup_input.hide() 
			btn_confirm.text = "Overwrite"
		else:
			is_overwriting = false
			popup_title.text = "Name your shop:"
			popup_input.show()
			popup_input.text = "" 
			btn_confirm.text = "Start game" 
			
	elif menu_mode == "load" and is_filled:
		_load_game(SAVE_FILE_TEMPLATE % slot_id)

func _on_popup_confirm_pressed() -> void:
	var save_path: String = SAVE_FILE_TEMPLATE % current_slot_id
	
	if is_deleting:
		if FileAccess.file_exists(save_path):
			DirAccess.remove_absolute(save_path)
		is_deleting = false
		action_popup.hide()
		_refresh_slots()
		return
		
	if is_overwriting:
		is_overwriting = false
		popup_title.text = "Name your new shop:"
		popup_title.add_theme_color_override("font_color", Color.WHITE) # Resetăm culoarea
		popup_input.show()
		popup_input.text = ""
		btn_confirm.text = "Start game"
		return
		
	# --- ZONA DE VALIDARE ---
	# 1. Tăiem spațiile libere de la început și final
	var shop_name: String = popup_input.text.strip_edges()
	
	# 2. Fallback dacă a dat doar Enter / a scris doar spații
	if shop_name.is_empty():
		shop_name = "Shop " + str(current_slot_id)
		
	# 3. Limitare (în caz de siguranță, deși Max Length din editor o face deja)
	if shop_name.length() > 20:
		shop_name = shop_name.left(20)
		
	# 4. Verificare Nume Identic
	if _is_name_duplicate(shop_name, current_slot_id):
		popup_title.text = "Numele există deja! Alege altul."
		# Îi dăm un feedback vizual roșu
		popup_title.add_theme_color_override("font_color", Color.RED)
		return # Oprim funcția aici! Nu închidem fereastra și nu salvăm.
		
	# --- TOTUL E OK, SALVĂM ---
	popup_title.remove_theme_color_override("font_color") # Curățăm roșul pentru data viitoare
	action_popup.hide()
	_start_new_game(save_path, shop_name)

func _on_transition_done() -> void:
	print("Animation finished. Attempting to load scene: ", LOADING_SCENE)
	
	var err := get_tree().change_scene_to_file(LOADING_SCENE)
	
	if err != OK:
		print("!!! CRITICAL ERROR !!!")
		print("Error code: ", err)
		print("Check if loading_screen.tscn exists at exact path: ", LOADING_SCENE)

func _on_delete_request(slot_id: int) -> void:
	current_slot_id = slot_id
	is_deleting = true
	is_overwriting = false # Ne asigurăm că nu se amestecă stările
	
	action_popup.show()
	popup_title.text = "Are you sure?"
	popup_input.hide()
	btn_confirm.text = "Yes, delete"
