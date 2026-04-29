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

@onready var dark_overlay = $DarkOverlay
@onready var receipt_node = $ReceiptNode
@onready var btn_close_credits = $ReceiptNode/BtnCloseCredits

@onready var shutter = $MetalShutter

# Referință către containerul de butoane
@onready var button_container = $ParallaxBackground/Layer5_Shaorma/MainGroup

var screen_center: Vector2
var base_positions: Array[Vector2] = []

func _ready():
	_update_screen_data()
	
	if not get_viewport().size_changed.is_connected(_update_screen_data):
		get_viewport().size_changed.connect(_update_screen_data)

	$Camera2D.position = screen_center
	
	# Conectăm semnalele butoanelor din container
	button_container.get_node("NewGameButton").pressed.connect(_on_new_game_pressed)
	button_container.get_node("LoadGameButton").pressed.connect(_on_load_game_pressed)
	button_container.get_node("SettingsButton").pressed.connect(_on_settings_pressed)
	button_container.get_node("CreditsButton").pressed.connect(_on_credits_pressed)
	button_container.get_node("QuitButton").pressed.connect(_on_quit_pressed)
	
	# Efect de "Juice" la hover pentru butoanele de pe rotisor
	for button in button_container.get_children():
		if button is BaseButton: 
			button.mouse_entered.connect(_on_button_hover.bind(button))
			button.mouse_exited.connect(_on_button_unhover.bind(button))

	btn_close_credits.pressed.connect(_on_close_credits_pressed)
	
	# --- MODIFICARE NOUĂ: Setăm butonul X la 25% din mărime ---
	btn_close_credits.scale = Vector2(0.25, 0.25)
	
	# Siguranță: La start, bonul e ascuns jos, iar întunericul e la zero
	receipt_node.position.y = 1200
	dark_overlay.modulate.a = 0.0

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


# --- Animații pentru Butoane ---
func _on_button_hover(btn: BaseButton):
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_QUAD)

func _on_button_unhover(btn: BaseButton):
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUAD)


# --- Tasta F11 pentru Fullscreen ---
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		var current_mode = DisplayServer.window_get_mode()
		if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


# --- Logica de Navigare ---
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

func _on_settings_pressed():
	print("Opening settings...")

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
		# NU mai oprim procesul aici! 
		# În schimb, aprindem lumina exact la valoarea ei de bază din scriptul tău
		tween.tween_property(light, "energy", light.base_energy, 0.6)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)
	
	# Bonul zboară în SUS
	tween.tween_property(receipt_node, "position:y", -1200, 0.6)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)
		
	# Re-iluminăm ecranul 
	tween.tween_property(dark_overlay, "modulate:a", 0.0, 0.6)
	
	# Callback: Ce se întâmplă la finalul animației
	tween.chain().tween_callback(func():
		button_container.show()
		receipt_node.position.y = 1200
		
		# ACUM repornim pâlpâitul, după ce animația de aprindere s-a terminat!
		for light in all_lights:
			light.set_process(true)
	)

func _on_quit_pressed():
	print("Se închide prăvălia. Zoom out și tragem obloanele...")
	
	# Dezactivăm butoanele
	button_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 1. Oprim muzica veselă de fundal (dramatism!)
	$BGMPlayer.stop()
	
	# 2. Dăm Play la sunetul greu de rulou metalic
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
