extends CanvasLayer

@onready var overlay: ColorRect = %ModalOverlay
@onready var menu_box: PanelContainer = %MenuBox
@onready var btn_resume: Button = %BtnResume
@onready var btn_settings: Button = %BtnSettings
@onready var btn_quit: Button = %BtnQuit

# Reference to the settings scene
@onready var settings_menu: Control = %SettingsMenu 

var is_open: bool = false
var _is_busy: bool = false

func _ready() -> void:
	menu_box.hide()
	if settings_menu:
		settings_menu.hide()
	
	btn_resume.pressed.connect(toggle_menu)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)
	
	# Listen for when the settings menu is closed
	if settings_menu and settings_menu.has_signal("closed"):
		settings_menu.closed.connect(_on_settings_closed)

func _unhandled_input(event: InputEvent) -> void:
	# Toggle the pause menu when pressing Escape (ui_cancel)
	if event.is_action_pressed("ui_cancel"):
		# Prevent toggling if the settings menu is currently open and active
		if settings_menu and settings_menu.visible:
			return
			
		toggle_menu()
		get_viewport().set_input_as_handled()

func toggle_menu() -> void:
	if _is_busy: return
	
	if is_open:
		_close_menu()
	else:
		_open_menu()

func _open_menu() -> void:
	is_open = true
	_is_busy = true
	get_tree().paused = true
	
	menu_box.show()
	
	# Break anchors so the tween can manipulate the position freely
	menu_box.set_anchors_preset(Control.PRESET_TOP_LEFT)
	
	# Center the panel on the X axis, but hide it way up on the Y axis
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	menu_box.position.x = (screen_size.x / 2.0) - (menu_box.size.x / 2.0)
	menu_box.position.y = -1000
	
	if overlay and overlay.has_method("fade_in"):
		overlay.fade_in(0.85, 0.5)
	elif overlay:
		overlay.show()
		
	# Animate the panel dropping down
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) # Ensure it processes while game is paused
	
	var target_y: float = (screen_size.y / 2.0) - (menu_box.size.y / 2.0)
	
	tween.tween_property(menu_box, "position:y", target_y, 0.7)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
		
	await tween.finished
	_is_busy = false

func _close_menu() -> void:
	is_open = false
	_is_busy = true
	
	if overlay and overlay.has_method("fade_out"):
		overlay.fade_out(0.6)
	elif overlay:
		overlay.hide()
		
	# Animate the panel pulling back up
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) # Ensure it processes while game is paused
	
	tween.tween_property(menu_box, "position:y", -1500, 0.6)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)
		
	await tween.finished
	
	menu_box.hide()
	get_tree().paused = false
	_is_busy = false

func _on_settings_pressed() -> void:
	# Hide the pause menu buttons while settings are open
	menu_box.hide()
	
	if settings_menu and settings_menu.has_method("open_settings"):
		settings_menu.open_settings()
	elif settings_menu:
		settings_menu.show()

func _on_settings_closed() -> void:
	# The settings menu handles its own closing animation and will hide itself.
	# We just need to bring back the pause menu buttons.
	# Since settings menu takes time to disappear, we want to drop our menu back in gracefully.
	menu_box.show()
	menu_box.set_anchors_preset(Control.PRESET_TOP_LEFT)
	
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	menu_box.position.x = (screen_size.x / 2.0) - (menu_box.size.x / 2.0)
	menu_box.position.y = -1000
	
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var target_y: float = (screen_size.y / 2.0) - (menu_box.size.y / 2.0)
	
	# Wait for the settings menu to mostly animate out of the way before we drop in!
	tween.tween_interval(0.4)
	
	tween.tween_property(menu_box, "position:y", target_y, 0.7)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
