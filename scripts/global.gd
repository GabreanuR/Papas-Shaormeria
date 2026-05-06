extends Node

# --- Variabilele noastre pentru sistemul de zile ---
var current_day: int = 1
var is_night: bool = false
var day_timer: Timer

# --- Variabilele colegilor (Starea stațiilor) ---
# Dacă nu știi exact ce tip de date așteaptă colegul tău, las-o nespecificată ("untyped") la început:
var selected_meat := "chicken"

func _ready() -> void:
	day_timer = Timer.new()
	day_timer.one_shot = true
	day_timer.timeout.connect(_on_day_timer_ended)
	add_child(day_timer)

func start_day(duration_seconds: float) -> void:
	day_timer.start(duration_seconds)

func _on_day_timer_ended() -> void:
	is_night = true
	get_tree().change_scene_to_file("res://scenes/menus/day_transition.tscn")
