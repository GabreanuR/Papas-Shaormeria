extends Control

# ---------------------------------------------------------
# 1. SIGNALS (Cum comunicăm înapoi cu Meniul Principal)
# ---------------------------------------------------------
signal action_confirmed       # Pentru Delete sau Overwrite
signal input_confirmed(text)  # Pentru New Game (trimite numele)
signal cancelled              # Dacă jucătorul se răzgândește

# ---------------------------------------------------------
# 2. ENUMS AND CONSTANTS
# ---------------------------------------------------------
enum Mode { CONFIRMATION, INPUT }

# ---------------------------------------------------------
# 5. PRIVATE VARIABLES
# ---------------------------------------------------------
var _current_mode: Mode = Mode.CONFIRMATION

# ---------------------------------------------------------
# 6. ONREADY VARIABLES (Fără trasee kilometrice, totul e local)
# ---------------------------------------------------------
@onready var title_label: Label = %PopupTitle
@onready var line_input: LineEdit = %PopupInput
@onready var btn_confirm: Button = %BtnConfirm
@onready var btn_cancel: Button = %BtnCancel

# Sfat PRO: Am folosit "%" (Unique Names). 
# Dă click dreapta pe nodurile de mai sus în ierarhie și alege "Access as Unique Name".
# Asta face codul imun chiar dacă muți butoanele prin alte containere!

# ---------------------------------------------------------
# 7. GODOT ENGINE FUNCTIONS
# ---------------------------------------------------------
func _ready() -> void:
	hide()
	btn_confirm.pressed.connect(_on_confirm_pressed)
	btn_cancel.pressed.connect(_on_cancel_pressed)

# ---------------------------------------------------------
# 8. PUBLIC FUNCTIONS (Cum "comandă" Meniul Principal acest pop-up)
# ---------------------------------------------------------

# Apelăm asta când vrem să ștergem sau să suprascriem o salvare
func ask_confirmation(title_text: String, confirm_btn_text: String) -> void:
	_current_mode = Mode.CONFIRMATION
	
	title_label.text = title_text
	title_label.remove_theme_color_override("font_color")
	
	btn_confirm.text = confirm_btn_text
	btn_cancel.text = "Cancel"
	
	line_input.hide()
	show()

# Apelăm asta când vrem un nume nou de magazin
func ask_input(title_text: String, confirm_btn_text: String, default_text: String = "") -> void:
	_current_mode = Mode.INPUT
	
	title_label.text = title_text
	title_label.remove_theme_color_override("font_color")
	
	btn_confirm.text = confirm_btn_text
	btn_cancel.text = "Cancel"
	
	line_input.text = default_text
	line_input.show()
	line_input.grab_focus() # Pune automat cursorul în căsuță!
	show()

# Dacă validarea eșuează în Meniul Principal, el ne poate spune să afișăm o eroare
func show_error(error_msg: String) -> void:
	title_label.text = error_msg
	title_label.add_theme_color_override("font_color", Color.RED)

# ---------------------------------------------------------
# 10. SIGNAL CALLBACKS
# ---------------------------------------------------------
func _on_confirm_pressed() -> void:
	if _current_mode == Mode.CONFIRMATION:
		hide()
		action_confirmed.emit()
	elif _current_mode == Mode.INPUT:
		# Lăsăm meniul principal să valideze și să decidă dacă închide pop-up-ul
		var text_to_send = line_input.text.strip_edges()
		input_confirmed.emit(text_to_send)

func _on_cancel_pressed() -> void:
	hide()
	cancelled.emit()
