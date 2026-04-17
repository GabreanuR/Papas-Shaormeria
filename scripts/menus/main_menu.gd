extends Control

# --- SETĂRI PARALLAX SOFT ---
# Am redus valorile. Cerul se mișcă abia insesizabil (0.005), shaorma din față se mișcă decent (0.03).
var parallax_multipliers = [0.005, 0.01, 0.015, 0.02, 0.03]

@onready var layers = [
	$ParallaxBackground/Layer1_Sky,
	$ParallaxBackground/Layer2_City,
	$ParallaxBackground/Layer3_Shop,
	$ParallaxBackground/Layer4_Name,
	$ParallaxBackground/Layer5_Shaorma
]

var screen_center: Vector2
var base_positions: Array[Vector2] = [] # Reținem punctul perfect centrat pentru fiecare strat

func _ready():
	# 1. Calculăm centrul și pozițiile de bază pentru parallax (codul tău existent)
	_update_screen_data()
	get_viewport().size_changed.connect(_update_screen_data)

	# 2. REPARARE CAMERĂ: Punem camera în centrul ecranului la început
	# Altfel, camera la (0,0) va centra colțul stânga-sus al meniului
	$Camera2D.position = screen_center
	# Calculăm centrele corecte la pornire
	_update_screen_data()
	
	# Verificăm dacă legătura există deja pentru a evita eroarea din consolă
	if not get_viewport().size_changed.is_connected(_update_screen_data):
		get_viewport().size_changed.connect(_update_screen_data)
		
	# Conectăm semnalele butoanelor principale
	$ButtonsContainer/NewGameButton.pressed.connect(_on_new_game_pressed)
	$ButtonsContainer/LoadGameButton.pressed.connect(_on_load_game_pressed)
	$ButtonsContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$ButtonsContainer/CreditsButton.pressed.connect(_on_credits_pressed)
	$ButtonsContainer/QuitButton.pressed.connect(_on_quit_pressed)
	
	# Adăugăm efectul de "Juice" (Animație la hover) pentru toate butoanele
	for button in $ButtonsContainer.get_children():
		if button is Button:
			button.pivot_offset = button.size / 2.0
			button.mouse_entered.connect(_on_button_hover.bind(button))
			button.mouse_exited.connect(_on_button_unhover.bind(button))

func _update_screen_data():
	screen_center = get_viewport_rect().size / 2.0
	base_positions.clear() # Curățăm lista în caz că facem resize
	
	for layer in layers:
		layer.pivot_offset = layer.size / 2.0
		# CALCULUL MAGIC: Găsim coordonata x,y (stânga-sus) ca imaginea să pice perfect pe centru
		var base_pos = screen_center - (layer.size / 2.0)
		base_positions.append(base_pos)
		
		# Setăm imaginea pe poziția centrată instantaneu (fără lerp, ca să nu „zboare” la pornire)
		layer.position = base_pos

func _process(delta):
	var mouse_pos = get_global_mouse_position()
	var offset = mouse_pos - screen_center
	
	for i in range(layers.size()):
		# Parallax-ul se scade/adună din poziția de BAZĂ (centrată), nu de la zero!
		var target_position = base_positions[i] - (offset * parallax_multipliers[i])
		layers[i].position = layers[i].position.lerp(target_position, 5.0 * delta)


# --- Animații pentru Butoane ---
func _on_button_hover(btn: Button):
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_QUAD)

func _on_button_unhover(btn: Button):
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
	print("Tranziție cinematică...")
	$ButtonsContainer.hide()
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 3. TRANZIȚIE RELATIVĂ: 
	# Deoarece camera e deja la screen_center, trebuie să adunăm offset-ul de mișcare
	var target_cam_pos = screen_center + Vector2(0, 300) 
	
	tween.tween_property($Camera2D, "position", target_cam_pos, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property($Camera2D, "zoom", Vector2(3.0, 3.0), 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	tween.chain().tween_callback(func(): get_tree().change_scene_to_file(GAME_SCENE))

func _on_load_game_pressed():
	print("Opening save slots...")

func _on_settings_pressed():
	print("Opening settings...")

func _on_credits_pressed():
	print("Game by: Amelia, Bianca, Maia, and Razvan.")

func _on_quit_pressed():
	get_tree().quit()
