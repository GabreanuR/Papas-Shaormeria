extends Control 

# Referințe UI
@onready var btn_buy_grill: Button = %BtnBuyGrill
@onready var btn_buy_oven: Button = %BtnBuyOven
@onready var btn_buy_bell: Button = %BtnBuyBell
@onready var btn_close: Button = %BtnClose

@onready var slots_grill: HBoxContainer = %SlotsGrill
@onready var slots_oven: HBoxContainer = %SlotsOven
@onready var slots_bell: HBoxContainer = %SlotsBell

# Referința pentru noul nostru fundal simplu
@onready var dark_bg: ColorRect = get_node_or_null("FundalNegru")

func _ready() -> void:
	# Conectăm butoanele
	btn_buy_grill.pressed.connect(func(): _on_buy_pressed("grill"))
	btn_buy_oven.pressed.connect(func(): _on_buy_pressed("oven"))
	btn_buy_bell.pressed.connect(func(): _on_buy_pressed("bell"))
	btn_close.pressed.connect(hide_menu)
	
	if dark_bg:
		dark_bg.color.a = 0.0 # Îl pornim invizibil
	
	# Inițializăm vizualul
	update_ui()

# Funcție apelată de day_transition.gd
func show_menu() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size = get_viewport_rect().size
	update_ui() # Forțăm prețurile și bateriile să se calculeze
	show()
	
	if dark_bg:
		var tween = create_tween()
		tween.tween_property(dark_bg, "color:a", 0.85, 0.3)

func hide_menu() -> void:
	if dark_bg:
		var tween = create_tween()
		tween.tween_property(dark_bg, "color:a", 0.0, 0.2)
		await tween.finished
	hide()

func update_ui() -> void:
	_update_row("grill", btn_buy_grill, slots_grill)
	_update_row("oven", btn_buy_oven, slots_oven)
	_update_row("bell", btn_buy_bell, slots_bell)

func _update_row(upgrade_id: String, btn: Button, slots_container: HBoxContainer) -> void:
	var current_lvl = Global.get_upgrade_level(upgrade_id)
	var max_lvl = Global.UPGRADES_DATA[upgrade_id]["max_level"]
	
	# Update Baterii
	for i in range(slots_container.get_child_count()):
		var slot = slots_container.get_child(i)
		if i < current_lvl:
			slot.color = Color(0.2, 0.8, 0.2, 1.0) # Verde aprins
		else:
			slot.color = Color(0.15, 0.15, 0.15, 1.0) # Gri închis
			
	# Update Buton și Preț
	if current_lvl >= max_lvl:
		btn.text = "MAX"
		btn.disabled = true
	else:
		var price = Global.UPGRADES_DATA[upgrade_id]["prices"][current_lvl]
		btn.text = "Buy $" + str(price)
		btn.disabled = Global.current_save["money"] < price

func _on_buy_pressed(upgrade_id: String) -> void:
	if Global.purchase_upgrade(upgrade_id):
		update_ui()
