extends PanelContainer

# UI References
@onready var m_btn_glasses: Button = %BtnGlasses
@onready var m_btn_wings: Button = %BtnWings
@onready var m_btn_shoes: Button = %BtnShoes
@onready var m_btn_close: Button = %BtnClose
@onready var modal_overlay = get_node_or_null("ModalOverlay")

func _ready() -> void:
	if modal_overlay:
		# Scoatem copilul imediat (acest lucru este permis de obicei, dar add_child la parinte nu e)
		remove_child(modal_overlay)
		# Chemam mutarea asincron, dupa ce parintele termina de initializat copiii
		call_deferred("_setup_modal_overlay")

	# Connect signals to item logic
	m_btn_glasses.pressed.connect(func(): _on_item_pressed("laser_glasses"))
	m_btn_wings.pressed.connect(func(): _on_item_pressed("angel_wings"))
	m_btn_shoes.pressed.connect(func(): _on_item_pressed("super_shoes"))

	# Connect close button
	m_btn_close.pressed.connect(hide_menu)

func _setup_modal_overlay() -> void:
	get_parent().add_child(modal_overlay)
	get_parent().move_child(modal_overlay, get_index())
	modal_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_overlay.size = get_viewport_rect().size
	modal_overlay.z_index = 100

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		update_ui()

func show_menu() -> void:
	show()
	if modal_overlay:
		modal_overlay.fade_in()

func hide_menu() -> void:
	if modal_overlay:
		modal_overlay.fade_out()
		await modal_overlay.fade_out_finished
	hide()

# Call this every time the menu is opened or an item is clicked
func update_ui() -> void:
	if m_btn_glasses == null:
		return
	_update_button_state(m_btn_glasses, "laser_glasses")
	_update_button_state(m_btn_wings, "angel_wings")
	_update_button_state(m_btn_shoes, "super_shoes")

func _update_button_state(btn: Button, item_id: String) -> void:
	if Global.is_item_unlocked(item_id):
		if Global.is_item_equipped(item_id):
			btn.text = "Unequip"
			btn.disabled = false
		else:
			btn.text = "Equip"
			btn.disabled = false
	else:
		var price: float = Global.ITEMS_DATA[item_id]["price"]
		btn.text = "Buy $" + str(int(price))

		if Global.current_save["money"] >= price:
			btn.disabled = false
		else:
			btn.disabled = true

func _on_item_pressed(item_id: String) -> void:
	if Global.is_item_unlocked(item_id):
		if Global.is_item_equipped(item_id):
			Global.unequip_item(item_id)
		else:
			Global.equip_item(item_id)
	else:
		Global.purchase_item(item_id)

	# Refresh all buttons after a transaction or equip action
	update_ui()
