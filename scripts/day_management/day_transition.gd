extends Control

# ---------------------------------------------------------
# 1. SIGNALS
# ---------------------------------------------------------

# ---------------------------------------------------------
# 2. ENUMS
# ---------------------------------------------------------
enum DayState { MORNING, NIGHT }

# ---------------------------------------------------------
# 3. CONSTANTS
# ---------------------------------------------------------

# ---------------------------------------------------------
# 4. PUBLIC VARIABLES
# ---------------------------------------------------------

# ---------------------------------------------------------
# 5. PRIVATE VARIABLES
# ---------------------------------------------------------
var _current_state: DayState = DayState.MORNING

# ---------------------------------------------------------
# 6. ONREADY VARIABLES
# ---------------------------------------------------------
@onready var _morning_bg: Control = %MorningBG
@onready var _night_bg: Control = %NightBG
@onready var _day_label: Label = %DayLabel
@onready var _action_btn: Button = %ActionBtn

# ---------------------------------------------------------
# 7. GODOT ENGINE FUNCTIONS
# ---------------------------------------------------------
func _ready() -> void:
	_action_btn.pressed.connect(_on_action_btn_pressed)

	# Check the global flag to determine whether we just ended a day.
	if Global.is_night:
		_set_state(DayState.NIGHT)
	else:
		_set_state(DayState.MORNING)

# ---------------------------------------------------------
# 8. PUBLIC FUNCTIONS
# ---------------------------------------------------------

# ---------------------------------------------------------
# 9. PRIVATE FUNCTIONS
# ---------------------------------------------------------
func _set_state(new_state: DayState) -> void:
	_current_state = new_state

	match _current_state:
		DayState.MORNING:
			_morning_bg.show()
			_night_bg.hide()
			_day_label.text = "Day " + str(Global.current_save["day"])
			_action_btn.text = "Start Day"
			_action_btn.show()

		DayState.NIGHT:
			_morning_bg.hide()
			_night_bg.show()
			# Day has NOT been incremented yet — it ticks over when the player
			# confirms "Next Day", so we show the day that just ended correctly.
			_day_label.text = "End of Day " + str(Global.current_save["day"])
			_action_btn.text = "Next Day"
			_action_btn.show()

# ---------------------------------------------------------
# 10. SIGNAL CALLBACKS
# ---------------------------------------------------------
func _on_action_btn_pressed() -> void:
	match _current_state:
		DayState.MORNING:
			# Start the global day timer, then load the gameplay scene.
			Global.start_day(30.0)
			get_tree().change_scene_to_file("res://scenes/gameplay/master/gameplay_master.tscn")

		DayState.NIGHT:
			# Increment the day and reset the night flag — the new day begins now.
			Global.current_save["day"] += 1
			Global.is_night = false
			_set_state(DayState.MORNING)
