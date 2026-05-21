extends PanelContainer

@onready var lbl_customers: Label = %LblCustomers
@onready var lbl_perfects: Label = %LblPerfects
@onready var lbl_tips: Label = %LblTips
@onready var lbl_total: Label = %LblTotal

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	
	# If the panel is already visible when the scene starts, force an update
	if visible:
		_refresh_stats()

func _on_visibility_changed() -> void:
	if visible:
		_refresh_stats()

func _refresh_stats() -> void:
	var stats = Global.daily_stats
	
	lbl_customers.text = str(stats.get("customers_served", 0))
	lbl_perfects.text = str(stats.get("perfect_orders", 0))
	lbl_tips.text = "$ %.2f" % stats.get("tips_earned", 0.0)
	lbl_total.text = "$ %.2f" % Global.daily_earnings
