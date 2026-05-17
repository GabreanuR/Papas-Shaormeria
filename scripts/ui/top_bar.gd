extends HBoxContainer

# Enumerăm cele două stări posibile ale barei
enum BarMode { HUB, GAMEPLAY }

# Această variabilă apare în Inspector! O poți schimba din Editor pentru fiecare scenă.
@export var mode: BarMode = BarMode.HUB

@onready var first_label: Label = %FirstLabel # Poate fi "Day X" sau "02:30"
@onready var second_label: Label = %SecondLabel # Poate fi "$150" (Global) sau "Profit: $20"
@onready var menu_btn: TextureButton = %MenuBtn

func _ready() -> void:
	menu_btn.pressed.connect(_on_menu_pressed)
	
	if mode == BarMode.HUB:
		# Modul Meniu (day_transition)
		_update_hub_display()
		Global.money_changed.connect(_on_global_money_changed)
		set_process(false) # Oprim funcția _process pentru că nu avem cronometru
		
	elif mode == BarMode.GAMEPLAY:
		# Modul Joc (gameplay_master)
		_update_gameplay_display()
		Global.daily_earnings_changed.connect(_on_daily_money_changed)
		set_process(true) # Pornim _process ca să calculăm secundele

# Funcția care rulează în fiecare cadru (doar în GAMEPLAY)
func _process(_delta: float) -> void:
	var time_left: float = Global._day_timer.time_left
	var minutes := int(time_left) / 60
	var seconds := int(time_left) % 60
	# Formatăm textul ca un ceas digital: "02:05"
	first_label.text = "%02d:%02d" % [minutes, seconds]

# --- FUNCȚII PENTRU HUB (Totaluri) ---
func _update_hub_display() -> void:
	first_label.text = "Day " + str(Global.current_save["day"])
	second_label.text = "$ " + str(Global.current_save["money"])

func _on_global_money_changed(new_amount: float) -> void:
	second_label.text = "$ " + str(new_amount)
	_animate_label(second_label)

# --- FUNCȚII PENTRU GAMEPLAY (Zilnice) ---
func _update_gameplay_display() -> void:
	second_label.text = "Profit: $ " + str(Global.daily_earnings)

func _on_daily_money_changed(new_amount: float) -> void:
	second_label.text = "Profit: $ " + str(new_amount)
	_animate_label(second_label)

# Un mic efect suculent când faci bani
func _animate_label(lbl: Label) -> void:
	var tween := create_tween()
	tween.tween_property(lbl, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.1)

func _on_menu_pressed() -> void:
	# Aici vom implementa Pop-up-ul cu Setări/Quit
	print("Deschide Meniul!")
