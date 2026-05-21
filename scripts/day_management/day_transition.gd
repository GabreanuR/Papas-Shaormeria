extends Control

enum DayState { MORNING, NIGHT }

const DEFAULT_DAY_DURATION := 10.0  # 3 minutes average
const GAMEPLAY_SCENE := "res://scenes/gameplay/master/gameplay_master.tscn"

var _current_state: DayState = DayState.MORNING

# ---------------------------------------------------------
# CONTAINERE PRINCIPALE
# ---------------------------------------------------------
@onready var _morning_container: Control = %MorningMenusContainer
@onready var _night_container: Control = %NightContainer

# ---------------------------------------------------------
# BUTOANE DIMINEAȚA
# ---------------------------------------------------------
@onready var _btn_start_day: TextureButton = %BtnStartDay
@onready var _btn_customize: TextureButton = %BtnCustomize
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
	# Conectăm butoanele principale de flux
	_btn_start_day.pressed.connect(_on_start_day_pressed)
	_btn_next_day.pressed.connect(_on_next_day_pressed)
	
	# Conectăm butoanele pentru a deschide scenele instanțiate
	_btn_customize.pressed.connect(func(): _customize_menu.show())
	_btn_upgrades.pressed.connect(func(): _upgrades_menu.show())
	_btn_achievements.pressed.connect(func(): _achievements_menu.show())

	# --- NOU: Inițializăm efectul de glow pentru toate butoanele ---
	_setup_button_glow(_btn_start_day)
	_setup_button_glow(_btn_customize)
	_setup_button_glow(_btn_upgrades)
	_setup_button_glow(_btn_achievements)

	# Verificăm starea din Global
	if Global.is_night:
		_set_state(DayState.NIGHT)
	else:
		_set_state(DayState.MORNING)

func _set_state(new_state: DayState) -> void:
	_current_state = new_state

	match _current_state:
		DayState.MORNING:
			_night_container.hide()
			_btn_next_day.hide()
			_summary_menu.hide()     # Close summary panel from previous night
			_upgrades_menu.hide()    # Ensure modals are closed on re-entry
			_customize_menu.hide()
			_achievements_menu.hide()
			_morning_container.show()

		DayState.NIGHT:
			_morning_container.hide()
			_night_container.show()
			_summary_menu.show()     # Auto-open summary at end of day
			_btn_next_day.show()

# ---------------------------------------------------------
# SIGNAL CALLBACKS (Fluxul zilelor)
# ---------------------------------------------------------
func _on_start_day_pressed() -> void:
	Global.start_day(DEFAULT_DAY_DURATION)
	get_tree().change_scene_to_file(GAMEPLAY_SCENE)

func _on_next_day_pressed() -> void:
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
