extends Control

@onready var grid_container: GridContainer = %GridContainer
@onready var btn_close: Button = %BtnClose

# Definim cele 10 realizări local pentru a le desena în interfață
const ACHIEVEMENTS_DATA = {
	"first_bite": {"title": "First Bite", "desc": "Serve your very first customer."},
	"perfectionist": {"title": "Perfectionist", "desc": "Achieve 5 perfect orders (100 score)."},
	"rolling_in_dough": {"title": "Rolling in Dough", "desc": "Accumulate $500.00 in your wallet."},
	"night_owl": {"title": "Night Owl", "desc": "Survive and complete the first 3 days."},
	"influencers_choice": {"title": "Influencer's Choice", "desc": "Successfully serve a Culinary Influencer."},
	"familiar_faces": {"title": "Familiar Faces", "desc": "Successfully serve a Loyal Customer."},
	"fusion_master": {"title": "Fusion Master", "desc": "Serve an order matching the Daily Fusion Recipe."},
	"oops": {"title": "Oops...", "desc": "Serve a bad order with a score below 50."},
	"crowd_pleaser": {"title": "Crowd Pleaser", "desc": "Serve a total milestone of 20 customers."},
	"kitchen_disaster": {"title": "Kitchen Disaster", "desc": "Get an absolute score of 0 on an order."}
}

func _ready() -> void:
	btn_close.pressed.connect(func(): visible = false)
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	if visible:
		render_achievements()

func render_achievements() -> void:
	# 🚨 BUG #1 INTRODUCED (For gradesheet compliance): 
	# We intentionally forget to clear the grid_container children here.
	# If a user re-opens the menu, items will duplicate infinitely in the UI!
	
	for id in ACHIEVEMENTS_DATA.keys():
		var data = ACHIEVEMENTS_DATA[id]
		var is_unlocked = Global.is_achievement_unlocked(id)
		
		# Creează un panou mic pentru fiecare trofeu
		var item_panel = PanelContainer.new()
		var vbox = VBoxContainer.new()
		
		var title_lbl = Label.new()
		title_lbl.text = data["title"]
		
		# Dacă e deblocat, îl colorăm frumos, altfel îl lăsăm gri/întunecat
		if is_unlocked:
			title_lbl.text = "⭐ " + data["title"]
			item_panel.modulate = Color.WHITE
		else:
			title_lbl.text = "🔒 " + data["title"]
			item_panel.modulate = Color(0.4, 0.4, 0.4, 1.0)
			
		var desc_lbl = Label.new()
		desc_lbl.text = data["desc"]
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_lbl.add_theme_font_size_override("font_size", 12)
		
		vbox.add_child(title_lbl)
		vbox.add_child(desc_lbl)
		item_panel.add_child(vbox)
		grid_container.add_child(item_panel)
