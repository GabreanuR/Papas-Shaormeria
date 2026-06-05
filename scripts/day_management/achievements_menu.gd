extends Control

@onready var grid_container: GridContainer = %GridContainer
@onready var btn_close: Button = %BtnClose

func _ready() -> void:
	btn_close.pressed.connect(func(): visible = false)
	# Folosim "call_deferred" ca să obligăm jocul să deseneze lista DOAR DUPĂ ce a terminat de încărcat fereastra complet:
	call_deferred("render_achievements")

func _on_visibility_changed() -> void:
	if visible:
		render_achievements()

func render_achievements() -> void:
	# Ștergem ce e vechi din grilă
	for child in grid_container.get_children():
		child.queue_free()
	
	for id in Global.ACHIEVEMENTS_DATA.keys():
		var data = Global.ACHIEVEMENTS_DATA[id]
		var is_unlocked = Global.is_achievement_unlocked(id)
		
		var item_panel = PanelContainer.new()
		item_panel.custom_minimum_size = Vector2(320, 80) # Dimensiunea ajustată pentru UI
		item_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var title_lbl = Label.new()
		title_lbl.add_theme_color_override("font_color", Color.BLACK) 
		
		if is_unlocked:
			title_lbl.text = "⭐ " + data["title"]
			item_panel.modulate = Color.WHITE
		else:
			title_lbl.text = "🔒 " + data["title"]
			item_panel.modulate = Color(0.8, 0.8, 0.8, 1.0)
			
		var desc_lbl = Label.new()
		desc_lbl.text = data["desc"]
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_lbl.add_theme_font_size_override("font_size", 14)
		desc_lbl.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1.0)) 
		
		vbox.add_child(title_lbl)
		vbox.add_child(desc_lbl)
		item_panel.add_child(vbox)
		grid_container.add_child(item_panel)
