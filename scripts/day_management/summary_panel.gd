extends Panel

@onready var lbl_customers: Label = %LblCustomers
@onready var lbl_perfects: Label = %LblPerfects
@onready var lbl_tips: Label = %LblTips
@onready var lbl_total: Label = %LblTotal

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	if visible:
		_refresh_stats()

func _refresh_stats() -> void:
	# Citim dicționarul din Global
	var stats = Global.daily_stats
	
	lbl_customers.text = str(stats["customers_served"])
	lbl_perfects.text = str(stats["perfect_orders"])
	lbl_tips.text = "$ " + str(stats["tips_earned"])
	
	# Folosim daily_earnings, exact cum l-ai denumit în noul Global
	lbl_total.text = "$ " + str(Global.daily_earnings)
