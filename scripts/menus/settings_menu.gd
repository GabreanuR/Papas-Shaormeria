extends Control

# ---------------------------------------------------------
# 1. SIGNALS
# ---------------------------------------------------------
signal closed

# ---------------------------------------------------------
# 5. PRIVATE VARIABLES
# ---------------------------------------------------------
var _is_busy: bool = false

# ---------------------------------------------------------
# 6. ONREADY VARIABLES
# ---------------------------------------------------------
@onready var overlay: ColorRect = $ModalOverlay

# Using Unique Names (%) so the UI layout can be changed without breaking code
@onready var settings_panel: Control = %SettingsPanel
@onready var btn_close: Button = %BtnCloseSettings
@onready var fullscreen_toggle: CheckButton = %FullscreenToggle
@onready var volume_slider: HSlider = %VolumeSlider

# ---------------------------------------------------------
# 7. GODOT ENGINE FUNCTIONS
# ---------------------------------------------------------
func _ready() -> void:
	# Îl mutăm instantaneu în afara ecranului și îl ascundem
	settings_panel.position.y = -2000 
	hide()

	# Sincronizăm setările fără să declanșăm animații
	_sync_ui_with_engine()

	# Conexiunile de semnale
	btn_close.pressed.connect(_on_close_pressed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	volume_slider.value_changed.connect(_on_volume_changed)

func _input(event: InputEvent) -> void:
	# Verificăm dacă a fost apăsată tasta F11
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		# Inversăm starea butonului vizual din Setări.
		# Magia: Făcând asta, Godot va declanșa AUTOMAT semnalul 
		# `_on_fullscreen_toggled`, executând logica ta perfectă de mai jos!
		fullscreen_toggle.button_pressed = not fullscreen_toggle.button_pressed

# ---------------------------------------------------------
# 8. PUBLIC FUNCTIONS
# ---------------------------------------------------------
func open_settings() -> void:
	if _is_busy: return
	_is_busy = true
	
	show()
	
	# Break anchors so the tween can manipulate the position freely
	settings_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	
	# Center the panel on the X axis, but hide it way up on the Y axis
	var screen_size := get_viewport_rect().size
	settings_panel.position.x = (screen_size.x / 2.0) - (settings_panel.size.x / 2.0)
	settings_panel.position.y = -1000
	
	# 1. Start the dark overlay fade
	overlay.fade_in(0.85, 0.5)
	
	# 2. Animate the panel dropping down
	var tween := create_tween()
	var target_y: float = (screen_size.y / 2.0) - (settings_panel.size.y / 2.0)
	
	tween.tween_property(settings_panel, "position:y", target_y, 0.7)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
		
	await tween.finished
	_is_busy = false

# ---------------------------------------------------------
# 9. PRIVATE FUNCTIONS
# ---------------------------------------------------------
func _sync_ui_with_engine() -> void:
	# Fullscreen
	var is_full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_toggle.set_pressed_no_signal(is_full)
	
	# Volume
	var master_bus_index := AudioServer.get_bus_index("Master")
	volume_slider.set_value_no_signal(db_to_linear(AudioServer.get_bus_volume_db(master_bus_index)))

# ---------------------------------------------------------
# 10. SIGNAL CALLBACKS
# ---------------------------------------------------------
func _on_close_pressed() -> void:
	if _is_busy: return
	_is_busy = true
	
	# 1. ANUNȚĂM MENIUL PRINCIPAL INSTANTANEU!
	closed.emit() 
	
	# 2. Începem animațiile de dispariție în ritmul lor
	overlay.fade_out(0.6)
	
	var tween := create_tween()
	tween.tween_property(settings_panel, "position:y", -1500, 0.6)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)
		
	await tween.finished
	
	hide()
	_is_busy = false

# ---------------------------------------------------------
# 10. SIGNAL CALLBACKS
# ---------------------------------------------------------
func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.call_deferred("window_set_mode", DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		_apply_windowed_mode()

func _on_volume_changed(value: float) -> void:
	var master_bus_index := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value))

# ---------------------------------------------------------
# 11. HELPER FUNCTIONS
# ---------------------------------------------------------
# Helper function to prevent OS auto-maximizing bugs when exiting fullscreen
func _apply_windowed_mode() -> void:
	# Use call_deferred to prevent input processing crashes
	DisplayServer.call_deferred("window_set_mode", DisplayServer.WINDOW_MODE_WINDOWED)
	
	# Force a smaller resolution to prevent OS auto-maximizing
	var windowed_size := Vector2i(1280, 720)
	DisplayServer.call_deferred("window_set_size", windowed_size)
	
	# Center the newly created window on the monitor
	var current_screen_pos := DisplayServer.screen_get_position()
	var current_screen_size := DisplayServer.screen_get_size()
	var window_pos: Vector2i = current_screen_pos + (current_screen_size / 2) - (windowed_size / 2)
	
	DisplayServer.call_deferred("window_set_position", window_pos)
	
