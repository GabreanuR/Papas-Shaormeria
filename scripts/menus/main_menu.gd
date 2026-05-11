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
@onready var button_container = $MainGroup
@onready var settings_menu = $SettingsMenu
@onready var credits_menu = $CreditsMenu
@onready var shutter = $MetalShutter
@onready var camera: Camera2D = $Camera2D
@onready var action_popup = $ActionPopup


@onready var saves_panel = $SaveSlotsPanel
@onready var btn_close_saves = $SaveSlotsPanel/MarginContainer/VBoxContainer/BtnCloseSaves
@onready var saves_title = $SaveSlotsPanel/MarginContainer/VBoxContainer/SaveSlotsLabel

@onready var slots = [
	$SaveSlotsPanel/MarginContainer/VBoxContainer/HBoxContainer/Slot1,
	$SaveSlotsPanel/MarginContainer/VBoxContainer/HBoxContainer/Slot2,
	$SaveSlotsPanel/MarginContainer/VBoxContainer/HBoxContainer/Slot3
]

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
		
	$Camera2D.position = get_viewport_rect().size / 2.0
	
	_connect_signals()
	_initialize_ui_state()

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
	if not settings_menu.closed.is_connected(_on_settings_closed):
		settings_menu.closed.connect(_on_settings_closed)
		print("Main Menu: Signal connected successfully!")
	credits_menu.back_requested.connect(_on_credits_closed)
	btn_close_saves.pressed.connect(_on_close_saves_pressed)
	
	# Action Pop-up
	action_popup.action_confirmed.connect(_on_popup_action_confirmed)
	action_popup.input_confirmed.connect(_on_popup_input_confirmed)
	
	action_popup.cancelled.connect(func(): 
		is_deleting = false
		is_overwriting = false
	)
	# "Juice" hover effects for main buttons
	for button in button_container.get_children():
		if button is BaseButton: 
			button.mouse_entered.connect(_on_button_hover.bind(button))
			button.mouse_exited.connect(_on_button_unhover.bind(button))

func _initialize_ui_state() -> void:
	action_popup.hide()
	# (Și saves_panel-ul, pe care îl vom refactoriza curând)

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

func _on_settings_pressed() -> void:
	print("Opening Settings...")
	button_container.hide()

	var tween := create_tween()
	_fade_shop_lights(tween, true)
	
	settings_menu.open_settings()

func _on_settings_closed() -> void:
	print("Main Menu: Received 'closed' signal!") # Dacă vezi asta în Output, conexiunea e bună
	
	# 1. Forțăm butoanele să apară imediat (fără tween, pentru test)
	button_container.show()
	
	# 2. Executăm restul logicii
	var tween := create_tween()
	_fade_shop_lights(tween, false)
	_resume_lights_processing()
	
func _on_credits_pressed() -> void:
	button_container.hide()
	
	var tween := create_tween()
	_fade_shop_lights(tween, true)
	
	credits_menu.play_credits()
		
func _on_credits_closed() -> void:
	button_container.show()
	
	var tween := create_tween()
	_fade_shop_lights(tween, false)
	
	tween.chain().tween_callback(func():
		_resume_lights_processing()
	)

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
		
	
	tween.chain().tween_callback(func(): 
		button_container.show()
		_resume_lights_processing()
	)

func _on_slot_clicked(slot_id: int, is_filled: bool) -> void:
	current_slot_id = slot_id
	is_deleting = false 
	
	if menu_mode == "new":
		if is_filled:
			is_overwriting = true
			# Comandăm componenta să ceară confirmare
			action_popup.ask_confirmation("Overwrite old save?", "Overwrite")
		else:
			is_overwriting = false
			# Comandăm componenta să ceară un text
			action_popup.ask_input("Name your shop:", "Start game")
			
	elif menu_mode == "load" and is_filled:
		_load_game(SAVE_FILE_TEMPLATE % slot_id)

# 1. Când jucătorul a zis "Da" la ștergere sau suprascriere
func _on_popup_action_confirmed() -> void:
	var save_path: String = SAVE_FILE_TEMPLATE % current_slot_id
	
	if is_deleting:
		if FileAccess.file_exists(save_path):
			DirAccess.remove_absolute(save_path)
		is_deleting = false
		_refresh_slots()
		
	elif is_overwriting:
		is_overwriting = false
		# Trecem din modul "Confirmare" în modul "Input" pentru numele noului shop
		action_popup.ask_input("Name your new shop:", "Start game")

# 2. Când jucătorul a dat Submit la numele magazinului
func _on_popup_input_confirmed(shop_name: String) -> void:
	var save_path: String = SAVE_FILE_TEMPLATE % current_slot_id
	
	# --- VALIDARE ---
	if shop_name.is_empty():
		shop_name = "Shop " + str(current_slot_id)
		
	if shop_name.length() > 20:
		shop_name = shop_name.left(20)
		
	if _is_name_duplicate(shop_name, current_slot_id):
		# Folosim funcția nouă din componentă pentru a arăta eroarea!
		action_popup.show_error("Numele există deja! Alege altul.")
		return
		
	# --- TOTUL E OK ---
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
	is_overwriting = false
	
	action_popup.ask_confirmation("Are you sure?", "Yes, delete")
