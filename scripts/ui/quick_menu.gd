extends CanvasLayer

@onready var overlay: ColorRect = %ModalOverlay
@onready var menu_box: PanelContainer = %MenuBox
@onready var btn_resume: Button = %BtnResume
@onready var btn_settings: Button = %BtnSettings
@onready var btn_quit: Button = %BtnQuit

# Reference to the settings scene
@onready var settings_menu: Control = %SettingsMenu 

var is_open: bool = false

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
	if is_open:
		_close_menu()
	else:
		_open_menu()

func _open_menu() -> void:
	is_open = true
	get_tree().paused = true
	menu_box.show()
	
	if overlay and overlay.has_method("fade_in"):
		overlay.fade_in()
	elif overlay:
		overlay.show()

func _close_menu() -> void:
	is_open = false
	menu_box.hide()
	
	if overlay and overlay.has_method("fade_out"):
		overlay.fade_out()
		if overlay.has_signal("fade_out_finished"):
			await overlay.fade_out_finished
		else:
			# Fallback in case the signal doesn't exist
			await get_tree().create_timer(0.3).timeout
	elif overlay:
		overlay.hide()
	
	get_tree().paused = false

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
	menu_box.show()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
