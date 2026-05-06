extends Node

var current_day: int = 1
var is_night: bool = false
var day_timer: Timer

func _ready() -> void:
	day_timer = Timer.new()
	day_timer.one_shot = true
	
	# Conectăm semnalul de expirare a timpului
	day_timer.timeout.connect(_on_day_timer_ended)
	
	add_child(day_timer)

func start_day(duration_seconds: float) -> void:
	day_timer.start(duration_seconds)

func _on_day_timer_ended() -> void:
	# Când expiră timpul, forțăm starea de noapte
	is_night = true
	
	# Indiferent în ce scenă ne aflăm, schimbăm ecranul către DayManager
	get_tree().change_scene_to_file("res://scenes/day_transition.tscn")
