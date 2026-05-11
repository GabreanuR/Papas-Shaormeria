extends Control

enum DayState { MORNING, NIGHT }

var current_state: DayState = DayState.MORNING

@onready var morning_bg = %MorningBG
@onready var night_bg = %NightBG
@onready var day_label = %DayLabel
@onready var action_btn = %ActionBtn

func _ready() -> void:
	action_btn.pressed.connect(_on_action_pressed)
	
	# Verificăm variabila globală pentru a ști dacă tocmai s-a terminat ziua
	if Global.is_night:
		_set_state(DayState.NIGHT)
	else:
		_set_state(DayState.MORNING)

func _set_state(new_state: DayState) -> void:
	current_state = new_state
	
	match current_state:
		DayState.MORNING:
			morning_bg.show()
			night_bg.hide()
			
			day_label.text = "Day " + str(Global.current_day)
			action_btn.text = "Start Day"
			action_btn.show()
			
		DayState.NIGHT:
			morning_bg.hide()
			night_bg.show()
			
			day_label.text = "End of Day " + str(Global.current_day)
			action_btn.text = "Next Day"
			action_btn.show()

func _on_action_pressed() -> void:
	if current_state == DayState.MORNING:
		# 1. Pornim cronometrul global
		Global.start_day(30.0) 
		
		# 2. Ne asigurăm că flag-ul este resetat
		Global.is_night = false 
		
		# 3. Sărim către prima ta scenă de gameplay
		# ATENȚIE: Înlocuiește calea de mai jos cu calea reală a primei stații
		get_tree().change_scene_to_file("res://scenes/gameplay/master/gameplay_master.tscn")
		
	elif current_state == DayState.NIGHT:
		# Trecem la dimineața următoare
		Global.current_day += 1
		Global.is_night = false
		
		# TODO: Apelul către funcția de Save (scrierea în JSON)
		
		_set_state(DayState.MORNING)
