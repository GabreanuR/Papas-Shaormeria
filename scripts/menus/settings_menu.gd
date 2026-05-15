extends Control

signal closed

var _is_busy: bool = false

@onready var overlay: ColorRect = $ModalOverlay

# Using Unique Names (%) so the UI layout can be changed without breaking code
@onready var settings_panel: Control = %SettingsPanel
@onready var btn_close: Button = %BtnCloseSettings
@onready var fullscreen_toggle: CheckButton = %FullscreenToggle
@onready var volume_slider: HSlider = %VolumeSlider

func _ready() -> void:
	# Move it instantly off-screen and hide it
	settings_panel.position.y = -2000 
	hide()

	# Synchronize settings without triggering animations
	_sync_ui_with_engine()

	# Connect signals
	btn_close.pressed.connect(_on_close_pressed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	volume_slider.value_changed.connect(_on_volume_changed)
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _unhandled_input(event: InputEvent) -> void:
	if visible and not _is_busy and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_close_pressed()

func _input(event: InputEvent) -> void:
	# Check if the F11 key was pressed
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		# Toggle the visual state of the button in Settings.
		# Magic: Doing this will AUTOMATICALLY trigger the
		# `_on_fullscreen_toggled` signal, executing the logic below perfectly!
		fullscreen_toggle.button_pressed = not fullscreen_toggle.button_pressed

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

func _sync_ui_with_engine() -> void:
	# Fullscreen
	var is_full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_toggle.set_pressed_no_signal(is_full)
	
	# Volume
	var master_bus_index := AudioServer.get_bus_index("Master")
	volume_slider.set_value_no_signal(db_to_linear(AudioServer.get_bus_volume_db(master_bus_index)))

func _on_viewport_size_changed() -> void:
	if visible and not _is_busy:
		var screen_size := get_viewport_rect().size
		settings_panel.position.x = (screen_size.x / 2.0) - (settings_panel.size.x / 2.0)
		settings_panel.position.y = (screen_size.y / 2.0) - (settings_panel.size.y / 2.0)

func _on_close_pressed() -> void:
	if _is_busy: return
	_is_busy = true
	
	# 1. NOTIFY MAIN MENU INSTANTLY!
	closed.emit() 
	
	# 2. Start the disappearance animations
	overlay.fade_out(0.6)
	
	var tween := create_tween()
	tween.tween_property(settings_panel, "position:y", -1500, 0.6)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)
		
	await tween.finished
	
	hide()
	_is_busy = false


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.call_deferred("window_set_mode", DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		_apply_windowed_mode()

func _on_volume_changed(value: float) -> void:
	var master_bus_index := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value))

# Helper function to prevent OS auto-maximizing bugs when exiting fullscreen
func _apply_windowed_mode() -> void:
	# Use call_deferred to prevent input processing crashes
	DisplayServer.call_deferred("window_set_mode", DisplayServer.WINDOW_MODE_WINDOWED)
	
	# Force a smaller resolution to prevent OS auto-maximizing
	var windowed_size := Vector2i(1280, 720)
	DisplayServer.call_deferred("window_set_size", windowed_size)
	
	var current_screen_pos := DisplayServer.screen_get_position()
	var current_screen_size := DisplayServer.screen_get_size()
	
	var screen_center := Vector2(current_screen_pos) + (Vector2(current_screen_size) / 2.0)
	var window_pos := Vector2i(screen_center - (Vector2(windowed_size) / 2.0))
	
	DisplayServer.call_deferred("window_set_position", window_pos)
	
