extends Control

enum DayState { MORNING, NIGHT }

const DEFAULT_DAY_DURATION := 180.0  # 3 minutes average
const GAMEPLAY_SCENE := "res://scenes/gameplay/master/gameplay_master.tscn"

@export var day_music: AudioStream

var _current_state: DayState = DayState.MORNING

# ---------------------------------------------------------
# CONTAINERE PRINCIPALE
# ---------------------------------------------------------
@onready var _morning_container: Control = %MorningMenusContainer
@onready var _night_container: Control = %NightContainer

# Am actualizat clasa de bază aici pentru a se potrivi cu noul nod rădăcină:
@onready var _top_bar: MarginContainer = $TopBar

# ---------------------------------------------------------
# BUTOANE DIMINEAȚA
# ---------------------------------------------------------
@onready var _btn_start_day: TextureButton = %BtnStartDay
@onready var _btn_customize: TextureButton = get_node_or_null("%BtnCustomize")
@onready var _btn_character_overlay: TextureButton = %BtnCharacterOverlay
@onready var _btn_upgrades: TextureButton = %BtnUpgrades
@onready var _btn_achievements: TextureButton = %BtnAchievements

# ---------------------------------------------------------
# BUTOANE NOAPTEA
# ---------------------------------------------------------
@onready var _btn_next_day: Button = %BtnNextDay

# ---------------------------------------------------------
# SCENE INSTANȚIATE (Pop-up-urile tale modulare)
# ---------------------------------------------------------
@onready var _summary_menu: Control = %SummaryPanel
@onready var _upgrades_menu: Control = %UpgradesMenu
@onready var _customize_menu: Control = %CustomizationMenu
@onready var _achievements_menu: Control = %AchievementsMenu

func _ready() -> void:
	# NOU: Forțăm starea TopBar-ului pentru HUB direct din cod.
	# Ne definește nevoia de rigoare, fără să depindem exclusiv de Inspector.
	if _top_bar and _top_bar.has_method("_setup_hub_mode"):
		_top_bar._setup_hub_mode()
		
	# Ascundem butonul de comandă (TextureButton) al caracterului din HUB
	# pentru că nu dă comenzi aici, și îi oprim și logica de pierdere a răbdării.
	var hub_customer = _morning_container.get_node_or_null("Customer")
	if hub_customer:
		if hub_customer.buton_comanda:
			hub_customer.buton_comanda.hide()
		hub_customer.set_process(false)
		hub_customer.scade_rabdare = false

	if day_music:
		AudioManager.play_music(day_music, 1.5)

	# Conectăm butoanele principale de flux
	_btn_start_day.pressed.connect(_on_start_day_pressed)
	_btn_next_day.pressed.connect(_on_next_day_pressed)
	
	# Muta meniurile în CanvasLayer ca să fure corect mouse-ul și să oprească luminile
	call_deferred("_setup_menu_layers")

	# Conectăm butoanele pentru a deschide scenele instanțiate
	if _btn_customize:
		_btn_customize.pressed.connect(func(): _customize_menu.show_menu())
		
	if _btn_character_overlay:
		# REPARAȚIE BUG: TextureButton fără textură nu prinde click-uri în Godot!
		if _btn_character_overlay.texture_normal == null:
			var empty_tex = PlaceholderTexture2D.new()
			empty_tex.size = _btn_character_overlay.size
			_btn_character_overlay.texture_normal = empty_tex
			_btn_character_overlay.modulate.a = 0.0 # Complet transparent
			
		_btn_character_overlay.pressed.connect(func(): _customize_menu.show_menu())
		
	_btn_upgrades.pressed.connect(func(): _upgrades_menu.show_menu())
	
	# Inițializăm efectul de glow pentru toate butoanele
	_setup_button_glow(_btn_start_day)
	if _btn_customize:
		_setup_button_glow(_btn_customize)
	_setup_button_glow(_btn_upgrades)
	_setup_button_glow(_btn_achievements)

	if _btn_character_overlay:
		_setup_button_glow(_btn_character_overlay)
		
	# Verificăm starea din Global
	if Global.is_night:
		_set_state(DayState.NIGHT)
	else:
		_set_state(DayState.MORNING)
		
	if has_node("%BtnAchievements") and has_node("%AchievementsMenu"):
		#%AchievementsMenu.visible = false
		%AchievementsMenu.queue_free()
		
		# Ștergem conectarea veche simplă a colegului ca să nu se bată cap în cap cu CanvasLayer-ul nostru
		if _btn_achievements.pressed.is_connected(func(): _achievements_menu.show()):
			_btn_achievements.pressed.disconnect(func(): _achievements_menu.show())
			
		%BtnAchievements.pressed.connect(func():
			# REPARAȚIE BUG #2: Dacă există deja un popup activ pe ecran, nu mai creăm altul!
			if get_tree().get_nodes_in_group("active_achievements_popup").size() > 0:
				return
				
			var canvas_layer = CanvasLayer.new()
			canvas_layer.layer = 100
			# Adăugăm stratul într-un grup ca să îl putem detecta la următorul click
			canvas_layer.add_to_group("active_achievements_popup") 
			add_child(canvas_layer)
			
			var achievements_scene = load("res://scenes/day_management/achievements_menu.tscn")
			var menu_instance = achievements_scene.instantiate()
			
			menu_instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			menu_instance.visible = true
			canvas_layer.add_child(menu_instance)
			
			var close_btn = menu_instance.get_node("%BtnClose")
			if close_btn:
				close_btn.pressed.connect(func():
					canvas_layer.queue_free()
				)
		)

func _setup_menu_layers() -> void:
	# Pentru a bloca automat interacțiunile cu fundalul și a declanșa mouse_exited
	# (ca să se oprească luminile butoanelor), punem meniurile statice în CanvasLayers
	if _customize_menu and _customize_menu.get_parent():
		var layer = CanvasLayer.new()
		layer.layer = 100
		_customize_menu.get_parent().remove_child(_customize_menu)
		add_child(layer)
		layer.add_child(_customize_menu)

	if _upgrades_menu and _upgrades_menu.get_parent():
		var layer2 = CanvasLayer.new()
		layer2.layer = 100
		_upgrades_menu.get_parent().remove_child(_upgrades_menu)
		add_child(layer2)
		layer2.add_child(_upgrades_menu)

func _set_state(new_state: DayState) -> void:
	_current_state = new_state

	match _current_state:
		DayState.MORNING:
			_night_container.hide()
			_btn_next_day.hide()
			_summary_menu.hide()     # Close summary panel from previous night
			_upgrades_menu.hide()    # Ensure modals are closed on re-entry
			_customize_menu.hide()
			_morning_container.show()
			_top_bar.show()

		DayState.NIGHT:
			_morning_container.hide()
			_night_container.show()
			_summary_menu.show()     # Auto-open summary at end of day
			_btn_next_day.show()
			_top_bar.hide()

# ---------------------------------------------------------
# SIGNAL CALLBACKS (Fluxul zilelor)
# ---------------------------------------------------------
func _on_start_day_pressed() -> void:
	AudioManager.stop_music(1.0)
	Global.start_day(DEFAULT_DAY_DURATION)
	get_tree().change_scene_to_file(GAMEPLAY_SCENE)

func _on_next_day_pressed() -> void:
	Global.reset_daily_stats() # Această funcție o ai deja în Global.gd!
	Global.advance_day()
	_set_state(DayState.MORNING)

# ---------------------------------------------------------
# FUNCȚII PRIVATE DE SISTEM
# ---------------------------------------------------------
func _setup_button_glow(btn: TextureButton) -> void:
	# Iterate over the button's children to find the light source
	for child in btn.get_children():
		if child is PointLight2D:
			# Only wire events if the light component has both methods
			if child.has_method("turn_on") and child.has_method("turn_off"):
				child.turn_off()  # Start with the light off
				btn.mouse_entered.connect(child.turn_on)
				btn.mouse_exited.connect(child.turn_off)
			# Stop searching once the light node is found
			break
