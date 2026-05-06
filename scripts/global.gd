extends Node

# ---------------------------------------------------------
# 1. SIGNALS (What does this script shout to other scenes?)
# ---------------------------------------------------------

# ---------------------------------------------------------
# 2. ENUMS AND CONSTANTS (Fixed values)
# ---------------------------------------------------------

# ---------------------------------------------------------
# 3. EXPORTED VARIABLES (Those that appear in the right-side Editor Inspector)
# ---------------------------------------------------------

# ---------------------------------------------------------
# 4. PUBLIC VARIABLES (Can be read/modified by other scripts)
# ---------------------------------------------------------
# --- Variabilele noastre pentru sistemul de zile ---
var current_day: int = 1
var is_night: bool = false
var day_timer: Timer

# --- Variabilele colegilor (Starea stațiilor) ---
# Dacă nu știi exact ce tip de date așteaptă colegul tău, las-o nespecificată ("untyped") la început:
var selected_meat := "chicken"

# ---------------------------------------------------------
# 5. PRIVATE VARIABLES (Prefixed with "_"; used only inside this script)
# ---------------------------------------------------------

# ---------------------------------------------------------
# 6. ONREADY VARIABLES (Links to the UI / Node Tree)
# ---------------------------------------------------------

# ---------------------------------------------------------
# 7. GODOT ENGINE FUNCTIONS (The built-in ones)
# ---------------------------------------------------------
func _ready() -> void:
	day_timer = Timer.new()
	day_timer.one_shot = true
	day_timer.timeout.connect(_on_day_timer_ended)
	add_child(day_timer)

# ---------------------------------------------------------
# 8. PUBLIC FUNCTIONS (Called by you from other scripts)
# ---------------------------------------------------------
func start_day(duration_seconds: float) -> void:
	day_timer.start(duration_seconds)

# ---------------------------------------------------------
# 9. PRIVATE FUNCTIONS (Prefixed with "_", used only internally here)
# ---------------------------------------------------------

# ---------------------------------------------------------
# 10. SIGNAL CALLBACKS (What happens when buttons/timers trigger)
# ---------------------------------------------------------
func _on_day_timer_ended() -> void:
	is_night = true
	get_tree().change_scene_to_file("res://scenes/menus/day_transition.tscn")
