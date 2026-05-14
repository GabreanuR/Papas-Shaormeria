extends Control

signal closed
signal request_load(slot_id: int)
signal request_new(slot_id: int, is_filled: bool)
signal request_delete(slot_id: int)

const SAVE_FILE_TEMPLATE = "user://save_slot_%d.json"

var _menu_mode: String = "" # "new" or "load"
var _is_busy: bool = false

var _tex_empty_normal: Texture2D = preload("res://assets/graphics/ui/slot_normal.png")
var _tex_empty_hover: Texture2D = preload("res://assets/graphics/ui/slot_hover.png")
var _tex_filled_normal: Texture2D = preload("res://assets/graphics/ui/slot_filled_normal.png")
var _tex_filled_hover: Texture2D = preload("res://assets/graphics/ui/slot_filled_hover.png")

@onready var overlay: ColorRect = $ModalOverlay
@onready var saves_panel: Control = %SaveSlotsPanel
@onready var saves_title: Label = %SaveSlotsLabel
@onready var btn_close: Button = %BtnCloseSaves

@onready var slots: Array[Button] = [%Slot1, %Slot2, %Slot3]
@onready var delete_btns: Array[TextureButton] = [%DeleteBtn1, %DeleteBtn2, %DeleteBtn3]
@onready var slot_labels: Array[Label] = [%SlotLabel1, %SlotLabel2, %SlotLabel3]

func _ready() -> void:
	saves_panel.position.y = -2000
	hide()
	overlay.hide() 
	
	btn_close.pressed.connect(_on_close_pressed)
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _unhandled_input(event: InputEvent) -> void:
	if visible and not _is_busy and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_close_pressed()

func open_menu(mode: String) -> void:
	if _is_busy: return
	_is_busy = true
	
	_menu_mode = mode
	saves_title.text = "New Game - Pick a slot" if mode == "new" else "Load Game - Choose a save"
	
	_refresh_slots()
	
	var screen_size := get_viewport_rect().size
	saves_panel.position.x = (screen_size.x / 2.0) - (saves_panel.size.x / 2.0)
	saves_panel.position.y = -1500
	
	show()
	overlay.show()
	
	overlay.fade_in(0.85, 0.5)
	
	var tween := create_tween()
	var target_y: float = (screen_size.y / 2.0) - (saves_panel.size.y / 2.0)
	
	tween.tween_property(saves_panel, "position:y", target_y, 0.7)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
		
	await tween.finished
	_is_busy = false

# Helper method so Main Menu can refresh after deleting a file
func refresh_display() -> void:
	_refresh_slots()

func _refresh_slots() -> void:
	for i in range(slots.size()):
		var slot_btn: Button = slots[i]
		var del_btn: TextureButton = delete_btns[i]
		var name_label: Label = slot_labels[i]
		var slot_id: int = i + 1
		
		var save_path: String = SAVE_FILE_TEMPLATE % slot_id
		var has_save: bool = FileAccess.file_exists(save_path)
		
		slot_btn.text = "" 
		slot_btn.modulate = Color.WHITE
		
		var style_normal := StyleBoxTexture.new()
		var style_hover := StyleBoxTexture.new()
		
		if has_save:
			var full_name: String = _get_shop_name_from_file(save_path)
			name_label.text = full_name.left(17) + "..." if full_name.length() > 20 else full_name
			name_label.show() 
			slot_btn.disabled = false
			
			style_normal.texture = _tex_filled_normal
			style_hover.texture = _tex_filled_hover
			del_btn.visible = (_menu_mode == "load")
		else:
			del_btn.visible = false
			
			if _menu_mode == "load":
				name_label.text = "EMPTY SLOT"
				name_label.show()
				slot_btn.disabled = true
				slot_btn.modulate = Color(0.5, 0.5, 0.5, 0.7)
			else:
				name_label.text = ""
				name_label.hide()
				slot_btn.disabled = false
				slot_btn.modulate = Color.WHITE
				
			style_normal.texture = _tex_empty_normal
			style_hover.texture = _tex_empty_hover

		slot_btn.add_theme_stylebox_override("normal", style_normal)
		slot_btn.add_theme_stylebox_override("hover", style_hover)
		
		# Disconnect old signals safely
		if slot_btn.pressed.is_connected(_on_slot_clicked):
			slot_btn.pressed.disconnect(_on_slot_clicked)
		slot_btn.pressed.connect(_on_slot_clicked.bind(slot_id, has_save))
		
		if not del_btn.pressed.is_connected(_on_delete_clicked):
			del_btn.pressed.connect(_on_delete_clicked.bind(slot_id))

func _get_shop_name_from_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return "No Save"
		
	var file := FileAccess.open(path, FileAccess.READ)
	if not file: 
		return "Error Reading File"
	
	var content := file.get_as_text()
	file.close()
	
	# Future-proof parsing: Use JSON instance to safely catch and log corruption
	var json := JSON.new()
	var error := json.parse(content)
	
	if error != OK:
		push_error("Save file corrupted or invalid JSON in '%s'. Error on line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return "Corrupt Save"
		
	var data = json.get_data()
	if typeof(data) == TYPE_DICTIONARY:
		if data.has("shop_name"):
			return str(data["shop_name"])
			
	return "Unknown Shop"

func _on_slot_clicked(slot_id: int, is_filled: bool) -> void:
	if _menu_mode == "load":
		request_load.emit(slot_id)
	elif _menu_mode == "new":
		request_new.emit(slot_id, is_filled)

func _on_delete_clicked(slot_id: int) -> void:
	request_delete.emit(slot_id)

func _on_viewport_size_changed() -> void:
	if visible and not _is_busy:
		var screen_size := get_viewport_rect().size
		saves_panel.position.x = (screen_size.x / 2.0) - (saves_panel.size.x / 2.0)
		saves_panel.position.y = (screen_size.y / 2.0) - (saves_panel.size.y / 2.0)

func _on_close_pressed() -> void:
	if _is_busy: return
	_is_busy = true
	
	# 1. NOTIFY MAIN MENU INSTANTLY!
	closed.emit() 
	
	# 2. Turn off the darkness
	overlay.fade_out(0.6)
	
	# 3. Animate panel back up
	var tween := create_tween()
	tween.tween_property(saves_panel, "position:y", -1500, 0.6)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)
		
	await tween.finished
	
	hide()
	_is_busy = false
