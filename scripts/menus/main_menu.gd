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

# Referință către noul loc unde stau butoanele
@onready var button_container = $ParallaxBackground/Layer5_Shaorma/ShaormaButtons

var screen_center: Vector2
var base_positions: Array[Vector2] = [] # Reținem punctul perfect centrat pentru fiecare strat

func _ready():
	# 1. Calculăm centrele corecte la pornire
	_update_screen_data()
	
	# 2. Verificăm dacă legătura există deja pentru a evita eroarea din consolă
	if not get_viewport().size_changed.is_connected(_update_screen_data):
		get_viewport().size_changed.connect(_update_screen_data)

	# 3. Punem camera în centrul ecranului la început
	$Camera2D.position = screen_center
	
	# 4. Conectăm semnalele butoanelor din noul container
	# Atenție: Asigură-te că numele de mai jos se potrivesc EXACT cu ce ai în Scene!
	button_container.get_node("NewGameButton").pressed.connect(_on_new_game_pressed)
	button_container.get_node("LoadGameButton").pressed.connect(_on_load_game_pressed)
	button_container.get_node("SettingsButton").pressed.connect(_on_settings_pressed)
	button_container.get_node("CreditsButton").pressed.connect(_on_credits_pressed)
	button_container.get_node("QuitButton").pressed.connect(_on_quit_pressed)
	
	# 5. Adăugăm efectul de "Juice" (Animație la hover) pentru toate butoanele
	for button in button_container.get_children():
		# BaseButton acoperă atât butoanele de text cât și TextureButton (cele grafice)
		if button is BaseButton: 
			# Am scos linia care forța pivot_offset. 
			# Dacă le-ai înclinat tu vizual în editor, Godot va folosi pivotul tău!
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
# Notă: Dacă ai micșorat butoanele din Inspector (ex: scale 0.5), 
# va trebui să modifici (1.1, 1.1) în (0.6, 0.6) și (1.0, 1.0) în (0.5, 0.5) 
# pentru ca ele să nu se facă brusc uriașe când pui mouse-ul pe ele.

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
	print("Tranziție cinematică...")
	
	# Ascundem grupul de butoane să nu mai apară la zoom
	button_container.hide()
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Efect de "Fade Out" pentru Titlu (Layer4) ca să dispară încet
	tween.tween_property(layers[3], "modulate:a", 0.0, 1.0)
	
	# Tranziția relativă a camerei (Adunăm offset-ul de mișcare la poziția curentă)
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
