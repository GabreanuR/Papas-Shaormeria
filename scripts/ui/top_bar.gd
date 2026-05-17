extends HBoxContainer

# Enumerăm cele două stări posibile ale barei
enum BarMode { HUB, GAMEPLAY }

# Această variabilă apare în Inspector! O poți schimba din Editor pentru fiecare scenă.
@export var mode: BarMode = BarMode.HUB

@onready var first_label: Label = %FirstLabel # "Day X" or "02:30"
@onready var second_label: Label = %SecondLabel # "$ 150" (Hub) or "Profit: $ 20" (Gameplay)
@onready var menu_btn: TextureButton = %MenuBtn

# Stored tween reference to prevent overlapping scale animations
var _label_tween: Tween

func _ready() -> void:
	menu_btn.pressed.connect(_on_menu_pressed)
	
	if mode == BarMode.HUB:
		# Hub mode (day_transition scene)
		_update_hub_display()
		Global.money_changed.connect(_on_global_money_changed)
		Global.day_changed.connect(_on_day_changed)
		set_process(false) # No timer to track in hub
		
	elif mode == BarMode.GAMEPLAY:
		# Gameplay mode (gameplay_master scene)
		_update_gameplay_display()
		Global.daily_earnings_changed.connect(_on_daily_money_changed)
		set_process(true) # Drive the countdown clock via _process

# Drives the countdown clock (GAMEPLAY mode only)
func _process(_delta: float) -> void:
	var time_left: float = Global.day_time_left  # Public property, not private _day_timer
	var minutes := int(time_left / 60.0)
	var seconds := int(time_left) % 60
	# Format as a digital clock: "02:05"
	first_label.text = "%02d:%02d" % [minutes, seconds]

# --- HUB FUNCTIONS (career totals) ---
func _update_hub_display() -> void:
	first_label.text = "Day " + str(Global.current_save["day"])
	second_label.text = "$ %d" % int(Global.current_save["money"])

func _on_global_money_changed(new_amount: float) -> void:
	second_label.text = "$ %d" % int(new_amount)
	_animate_label(second_label)

func _on_day_changed(new_day: int) -> void:
	first_label.text = "Day " + str(new_day)
	_animate_label(first_label)

# --- GAMEPLAY FUNCTIONS (daily earnings) ---
func _update_gameplay_display() -> void:
	second_label.text = "Profit: $ %d" % int(Global.daily_earnings)

func _on_daily_money_changed(new_amount: float) -> void:
	second_label.text = "Profit: $ %d" % int(new_amount)
	_animate_label(second_label)

# Scale-pulse effect when values change. Kills any in-progress tween first
# to prevent overlapping animations when multiple updates fire in quick succession.
func _animate_label(lbl: Label) -> void:
	if _label_tween:
		_label_tween.kill()
	_label_tween = create_tween()
	_label_tween.tween_property(lbl, "scale", Vector2(1.2, 1.2), 0.1)
	_label_tween.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.1)

func _on_menu_pressed() -> void:
	## TODO: Emit a signal or show the pause/settings panel here.
	pass
