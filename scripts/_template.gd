extends Node
# If this script is heavily reusable, you can give it a class_name
# class_name ClassName

# ---------------------------------------------------------
# 1. SIGNALS (What does this script shout to other scenes?)
# ---------------------------------------------------------
signal job_finished(score: int)
signal item_dropped

# ---------------------------------------------------------
# 2. ENUMS AND CONSTANTS (Fixed values)
# ---------------------------------------------------------
enum State { IDLE, WORKING, DONE }
const MAX_TIME: float = 30.0

# ---------------------------------------------------------
# 3. EXPORTED VARIABLES (Those that appear in the right-side Editor Inspector)
# ---------------------------------------------------------
@export var speed: float = 5.0
@export var is_active: bool = true

# ---------------------------------------------------------
# 4. PUBLIC VARIABLES (Can be read/modified by other scripts)
# ---------------------------------------------------------
var current_state: State = State.IDLE
var score: int = 0

# ---------------------------------------------------------
# 5. PRIVATE VARIABLES (Prefixed with "_"; used only inside this script)
# ---------------------------------------------------------
var _click_count: int = 0
var _timer_active: bool = false

# ---------------------------------------------------------
# 6. ONREADY VARIABLES (Links to the UI / Node Tree)
# ---------------------------------------------------------
@onready var animation_player = $AnimationPlayer
@onready var title_label = %TitleLabel

# ---------------------------------------------------------
# 7. GODOT ENGINE FUNCTIONS (The built-in ones)
# ---------------------------------------------------------
func _ready() -> void:
	# Initializations and signal connections go here
	pass

func _process(delta: float) -> void:
	# Frame-by-frame logic goes here
	pass

# ---------------------------------------------------------
# 8. PUBLIC FUNCTIONS (Called by you from other scripts)
# ---------------------------------------------------------
func start_machine() -> void:
	current_state = State.WORKING
	animation_player.play("work")

func get_current_score() -> int:
	return score

# ---------------------------------------------------------
# 9. PRIVATE FUNCTIONS (Prefixed with "_", used only internally here)
# ---------------------------------------------------------
func _calculate_bonus() -> void:
	score += 10

# ---------------------------------------------------------
# 10. SIGNAL CALLBACKS (What happens when buttons/timers trigger)
# ---------------------------------------------------------
func _on_button_pressed() -> void:
	_calculate_bonus()
	job_finished.emit(score)
