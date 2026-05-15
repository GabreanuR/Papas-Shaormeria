extends Control

signal action_confirmed       # Emitted for Delete or Overwrite actions
signal input_confirmed(text)  # Emitted for New Game to send the chosen name
signal cancelled              # Emitted when the user cancels the action

enum Mode { CONFIRMATION, INPUT }

var _current_mode: Mode = Mode.CONFIRMATION

@onready var title_label: Label = %PopupTitle
@onready var line_input: LineEdit = %PopupInput
@onready var btn_confirm: Button = %BtnConfirm
@onready var btn_cancel: Button = %BtnCancel

func _ready() -> void:
	hide()
	btn_confirm.pressed.connect(_on_confirm_pressed)
	btn_cancel.pressed.connect(_on_cancel_pressed)
	line_input.text_submitted.connect(func(_text): _on_confirm_pressed())

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_cancel_pressed()

# Called when asking to delete or overwrite a save
func ask_confirmation(title_text: String, confirm_btn_text: String) -> void:
	_current_mode = Mode.CONFIRMATION
	
	title_label.text = title_text
	title_label.theme_type_variation = "Label"
	
	btn_confirm.text = confirm_btn_text
	btn_cancel.text = "Cancel"
	
	line_input.hide()
	show()
	btn_confirm.grab_focus()

# Called to prompt the user for a new shop name
func ask_input(title_text: String, confirm_btn_text: String, default_text: String = "") -> void:
	_current_mode = Mode.INPUT
	
	title_label.text = title_text
	title_label.theme_type_variation = "Label"
	
	btn_confirm.text = confirm_btn_text
	btn_cancel.text = "Cancel"
	
	line_input.text = default_text
	line_input.show()
	line_input.grab_focus()
	show()

# Called by the Main Menu if validation fails, displaying an error message
func show_error(error_msg: String) -> void:
	title_label.text = error_msg
	title_label.theme_type_variation = "ErrorLabel"

func _on_confirm_pressed() -> void:
	if _current_mode == Mode.CONFIRMATION:
		hide()
		action_confirmed.emit()
	elif _current_mode == Mode.INPUT:
		# Let the main menu validate the input and decide whether to close the popup
		var text_to_send = line_input.text.strip_edges()
		input_confirmed.emit(text_to_send)

func _on_cancel_pressed() -> void:
	hide()
	cancelled.emit()
