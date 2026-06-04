extends MarginContainer

# Enum defining the two possible states for the top bar
enum BarMode { HUB, GAMEPLAY }

# This variable appears in the Inspector! You can change it from the Editor for each scene.
@export var mode: BarMode = BarMode.HUB

# ---------------------------------------------------------
# GRAFICI EXPORTATE PENTRU EDITOR
# ---------------------------------------------------------
@export_group("Hub Graphics")
@export var hub_info_style: StyleBox
@export var hub_btn_normal: Texture2D
@export var hub_btn_hover: Texture2D
@export var hub_btn_pressed: Texture2D

@export_group("Gameplay Graphics")
@export var gameplay_info_style: StyleBox
@export var gameplay_btn_normal: Texture2D
@export var gameplay_btn_hover: Texture2D
@export var gameplay_btn_pressed: Texture2D

# ---------------------------------------------------------
# REFERINȚE NODURI
# ---------------------------------------------------------
@onready var first_label: Label = %LblDay
@onready var second_label: Label = %LblProfit
@onready var menu_btn: TextureButton = %MenuBtn
@onready var quick_menu: CanvasLayer = $QuickMenu

@onready var info_bg: PanelContainer = %InfoBackground 
@onready var ticket_bg: PanelContainer = %TicketBackground

func _ready() -> void:
	menu_btn.pressed.connect(_on_menu_pressed)
	
	if mode == BarMode.HUB:
		_setup_hub_mode()
	elif mode == BarMode.GAMEPLAY:
		_setup_gameplay_mode()

func _setup_hub_mode() -> void:
	_update_hub_display()
	if not Global.money_changed.is_connected(_on_global_money_changed):
		Global.money_changed.connect(_on_global_money_changed)
	if not Global.day_changed.is_connected(_on_day_changed):
		Global.day_changed.connect(_on_day_changed)
	set_process(false) 
	
	# 1. Ascundem invizibil șina de bonuri
	ticket_bg.self_modulate.a = 0.0
	
	# 2. Aplicăm grafica de fundal pentru informații
	if hub_info_style:
		info_bg.add_theme_stylebox_override("panel", hub_info_style)
		
	# 3. Aplicăm cele 3 texturi pentru butonul de meniu (Meniul de Hub)
	menu_btn.texture_normal = hub_btn_normal
	menu_btn.texture_hover = hub_btn_hover
	menu_btn.texture_pressed = hub_btn_pressed

func _setup_gameplay_mode() -> void:
	_update_gameplay_display()
	if not Global.daily_earnings_changed.is_connected(_on_daily_money_changed):
		Global.daily_earnings_changed.connect(_on_daily_money_changed)
	set_process(false) 
	
	# 1. Ascundem invizibil șina de bonuri (la fel ca în HUB)
	ticket_bg.self_modulate.a = 0.0
	
	# 2. Aplicăm grafica de fundal pentru informații
	if gameplay_info_style:
		info_bg.add_theme_stylebox_override("panel", gameplay_info_style)
		
	# 3. Aplicăm cele 3 texturi pentru butonul de meniu (Clopoțel/Bon etc.)
	menu_btn.texture_normal = gameplay_btn_normal
	menu_btn.texture_hover = gameplay_btn_hover
	menu_btn.texture_pressed = gameplay_btn_pressed

# ---------------------------------------------------------
# LOGICA DE TIMER (GAMEPLAY)
# ---------------------------------------------------------
#func _process(_delta: float) -> void:
	#var time_left: float = Global.day_time_left
	#var minutes := int(time_left / 60.0)
	#var seconds := int(time_left) % 60
	#first_label.text = "%02d:%02d" % [minutes, seconds]
	
func update_customer_counter(serviti: int, total: int) -> void:
	first_label.text = str(serviti) + " / " + str(total)
	_animate_label(first_label) # Refolosim efectul tău fain de mărire a textului!

# ---------------------------------------------------------
# HUB FUNCTIONS 
# ---------------------------------------------------------
func _update_hub_display() -> void:
	first_label.text = "Day " + str(int(Global.current_save["day"]))
	second_label.text = "$ %.2f" % float(Global.current_save["money"])

func _on_global_money_changed(new_amount: float) -> void:
	second_label.text = "$ %.2f" % new_amount
	_animate_label(second_label)

func _on_day_changed(new_day: int) -> void:
	first_label.text = "Day " + str(int(new_day))
	_animate_label(first_label)

# ---------------------------------------------------------
# GAMEPLAY FUNCTIONS 
# ---------------------------------------------------------
func _update_gameplay_display() -> void:
	second_label.text = "Profit: $ %.2f" % Global.daily_earnings

func _on_daily_money_changed(new_amount: float) -> void:
	second_label.text = "Profit: $ %.2f" % new_amount
	_animate_label(second_label)

# ---------------------------------------------------------
# UTILITARE
# ---------------------------------------------------------
func _animate_label(lbl: Label) -> void:
	lbl.pivot_offset = lbl.size / 2.0
	
	if lbl.has_meta("tween"):
		var old_tween: Tween = lbl.get_meta("tween")
		if old_tween and old_tween.is_valid():
			old_tween.kill()
			
	var tween := create_tween()
	lbl.set_meta("tween", tween)
	
	tween.tween_property(lbl, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.1)

func _on_menu_pressed() -> void:
	if is_instance_valid(quick_menu):
		quick_menu.toggle_menu()
