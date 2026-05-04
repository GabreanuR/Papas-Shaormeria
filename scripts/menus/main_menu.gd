extends Control

# --- SETĂRI PARALLAX SOFT ---
var parallax_multipliers = [0.005, 0.01, 0.015, 0.02, 0.015]

@onready var layers = [
	$ParallaxBackground/Layer1_Sky,
	$ParallaxBackground/Layer2_City,
	$ParallaxBackground/Layer3_Shop,
	$ParallaxBackground/Layer4_Name,
	$ParallaxBackground/Layer5_Shaorma
]

# --- UI REFERINȚE ---
@onready var dark_overlay = $DarkOverlay
@onready var receipt_node = $ReceiptNode
@onready var btn_close_credits = $ReceiptNode/BtnCloseCredits

@onready var shutter = $MetalShutter
@onready var button_container = $ParallaxBackground/Layer5_Shaorma/MainGroup

@onready var settings_panel = $SettingsPanel
@onready var btn_close_settings = $SettingsPanel/MarginContainer/VBoxContainer/BtnCloseSettings
# ATENȚIE: Verifică dacă calea de mai jos e corectă pentru CheckButton-ul tău
@onready var fullscreen_toggle = $SettingsPanel/MarginContainer/VBoxContainer/FullscreenToggleControl/FullscreenToggle 

var screen_center: Vector2
var base_positions: Array[Vector2] = []

func _ready():
	_update_screen_data()
	
	if not get_viewport().size_changed.is_connected(_update_screen_data):
		get_viewport().size_changed.connect(_update_screen_data)

	$Camera2D.position = screen_center
	
	# --- CONECTĂRI BUTOANE PRINCIPALE ---
	button_container.get_node("NewGameButton").pressed.connect(_on_new_game_pressed)
	button_container.get_node("LoadGameButton").pressed.connect(_on_load_game_pressed)
	button_container.get_node("SettingsButton").pressed.connect(_on_settings_pressed)
	button_container.get_node("CreditsButton").pressed.connect(_on_credits_pressed)
	button_container.get_node("QuitButton").pressed.connect(_on_quit_pressed)
	
	# --- CONECTĂRI UI SECUNDAR ---
	btn_close_settings.pressed.connect(_on_close_settings_pressed)
	btn_close_credits.pressed.connect(_on_close_credits_pressed)
	
	# Conectăm butonul de Fullscreen din UI
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	
	# Sincronizăm starea butonului cu modul actual al ferestrei (la pornire)
	var is_full = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_toggle.button_pressed = is_full
	
	# Efect de "Juice" la hover pentru butoanele de pe rotisor
	for button in button_container.get_children():
		if button is BaseButton: 
			button.mouse_entered.connect(_on_button_hover.bind(button))
			button.mouse_exited.connect(_on_button_unhover.bind(button))

	# Setări inițiale sigure
	btn_close_credits.scale = Vector2(0.25, 0.25)
	receipt_node.position.y = 1200
	dark_overlay.modulate.a = 0.0
	
	# Asigurăm că Setările sunt ascunse la pornire (offset sus)
	settings_panel.position.y = -1000

func _update_screen_data():
	screen_center = get_viewport_rect().size / 2.0
	base_positions.clear() 
	
	for layer in layers:
		layer.pivot_offset = layer.size / 2.0
		var base_pos = screen_center - (layer.size / 2.0)
		base_positions.append(base_pos)
		layer.position = base_pos

func _process(delta):
	var mouse_pos = get_global_mouse_position()
	var offset = mouse_pos - screen_center
	
	for i in range(layers.size()):
		var target_position = base_positions[i] - (offset * parallax_multipliers[i])
		layers[i].position = layers[i].position.lerp(target_position, 5.0 * delta)

# --- ANIMAȚII BUTOANE ---
func _on_button_hover(btn: BaseButton):
	var tween = create_tween()
	tween.set_parallel(true) # Scalarea și întunecarea se întâmplă simultan
	
	btn.pivot_offset = btn.size / 2
	
	# Mărire de exact 5% (1.05)
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1)\
		.set_trans(Tween.TRANS_QUAD)
		
	# Întunecare ușoară (80% din luminozitatea originală)
	tween.tween_property(btn, "modulate", Color(0.8, 0.8, 0.8, 1.0), 0.1)

func _on_button_unhover(btn: BaseButton):
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Revenire la dimensiunea inițială
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)\
		.set_trans(Tween.TRANS_QUAD)
		
	# Revenire la luminozitatea normală (alb pur)
	tween.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)
	
# --- SISTEM FULLSCREEN ---
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		_toggle_fullscreen()

# Funcție unificată pentru F11 și butonul din UI
func _toggle_fullscreen():
	var current_mode = DisplayServer.window_get_mode()
	var is_full = current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN
	
	if is_full:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		fullscreen_toggle.button_pressed = false # Sincronizăm butonul vizual
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		fullscreen_toggle.button_pressed = true # Sincronizăm butonul vizual

# Ce se întâmplă când dai click pe CheckButton-ul din Settings
func _on_fullscreen_toggled(button_pressed: bool):
	var current_mode = DisplayServer.window_get_mode()
	var is_full = current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN
	
	# Schimbăm doar dacă e nevoie (evităm loop-uri ciudate)
	if button_pressed != is_full:
		_toggle_fullscreen()


# --- LOGICĂ NAVIGARE Meniuri ---
const GAME_SCENE = "res://scenes/day_transition.tscn"
const LOAD_MENU = "res://scenes/load_menu.tscn"

func _on_new_game_pressed():
	print("Tranziție cinematică spre joc nou...")
	button_container.hide()
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(layers[3], "modulate:a", 0.0, 1.0)
	var target_cam_pos = screen_center + Vector2(0, 300) 
	
	tween.tween_property($Camera2D, "position", target_cam_pos, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property($Camera2D, "zoom", Vector2(3.0, 3.0), 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	tween.chain().tween_callback(func(): get_tree().change_scene_to_file(GAME_SCENE))

func _on_load_game_pressed():
	print("Se deschide meniul de salvări...")
	get_tree().change_scene_to_file(LOAD_MENU)

# --- SETTINGS MENU ---
func _on_settings_pressed():
	print("Deschidem Setările...")
	button_container.hide()
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# --- STINGEM LUMINILE ---
	var all_lights = get_tree().get_nodes_in_group("shop_lights")
	for light in all_lights:
		light.set_process(false) 
		tween.tween_property(light, "energy", 0.0, 0.4)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(dark_overlay, "modulate:a", 0.85, 0.5)
	
	var target_pos = screen_center - (settings_panel.size / 2.0)
	tween.tween_property(settings_panel, "position", target_pos, 0.7)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

func _on_close_settings_pressed():
	print("Închidem Setările...")
	var tween = create_tween()
	tween.set_parallel(true)
	
	# --- APRINDEM LUMINILE ---
	var all_lights = get_tree().get_nodes_in_group("shop_lights")
	for light in all_lights:
		tween.tween_property(light, "energy", light.base_energy, 0.6)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)
	
	var hidden_pos = Vector2(settings_panel.position.x, -1000)
	tween.tween_property(settings_panel, "position", hidden_pos, 0.6)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)
		
	tween.tween_property(dark_overlay, "modulate:a", 0.0, 0.5)
	
	tween.chain().tween_callback(func(): 
		button_container.show()
		# Repornim pâlpâitul după ce s-au aprins
		for light in all_lights:
			light.set_process(true)
	)
	
	

# --- CREDITS MENU ---
func _on_credits_pressed():
	print("Se tipărește bonul de credite...")
	
	button_container.hide()
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	var all_lights = get_tree().get_nodes_in_group("shop_lights")
	for light in all_lights:
		light.set_process(false) 
		tween.tween_property(light, "energy", 0.0, 0.4)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(dark_overlay, "modulate:a", 0.85, 0.5)
	tween.tween_property(receipt_node, "position:y", -50, 0.8)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
		
func _on_close_credits_pressed():
	print("Închidem bonul...")
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	var all_lights = get_tree().get_nodes_in_group("shop_lights")
	for light in all_lights:
		tween.tween_property(light, "energy", light.base_energy, 0.6)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(receipt_node, "position:y", -1200, 0.6)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)
		
	tween.tween_property(dark_overlay, "modulate:a", 0.0, 0.6)
	
	tween.chain().tween_callback(func():
		button_container.show()
		receipt_node.position.y = 1200
		
		for light in all_lights:
			light.set_process(true)
	)

# --- QUIT ---
func _on_quit_pressed():
	print("Se închide prăvălia. Zoom out și tragem obloanele...")
	
	button_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$BGMPlayer.stop()
	$ShutterSFX.play()
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	var all_lights = get_tree().get_nodes_in_group("shop_lights")
	for light in all_lights:
		light.set_process(false) 
		tween.tween_property(light, "energy", 0.0, 0.4)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)
	
	tween.tween_property($Camera2D, "zoom", Vector2(0.98, 0.98), 0.7)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(shutter, "position", Vector2(-20, -10), 3.0)\
		.set_trans(Tween.TRANS_QUINT)\
		.set_ease(Tween.EASE_OUT)
		
	tween.chain().tween_callback(func(): get_tree().quit())
	
