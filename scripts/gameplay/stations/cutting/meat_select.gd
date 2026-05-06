extends Node2D

@onready var chicken := $Chicken
@onready var beef := $Beef

@onready var chicken_area := $Chicken/Area2D
@onready var beef_area := $Beef/Area2D

@onready var fade_overlay: ColorRect = $FadeOverlay

var selected := false


func _ready():
	fade_overlay.position = Vector2.ZERO
	fade_overlay.size = get_viewport_rect().size
	fade_overlay.color = Color(0, 0, 0, 0)
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	setup_hover(chicken)
	setup_hover(beef)

	chicken_area.input_event.connect(_on_chicken_click)
	beef_area.input_event.connect(_on_beef_click)


func setup_hover(node: Node2D):
	var area = node.get_node("Area2D")

	area.mouse_entered.connect(func():
		if not selected:
			var tween = node.create_tween()
			tween.tween_property(node, "scale", Vector2(1.015, 1.015), 0.18)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_OUT)
	)

	area.mouse_exited.connect(func():
		if not selected:
			var tween = node.create_tween()
			tween.tween_property(node, "scale", Vector2.ONE, 0.18)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_OUT)
	)


func _on_chicken_click(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_meat("chicken")


func _on_beef_click(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_meat("beef")


func select_meat(meat_type: String):
	if selected:
		return

	selected = true
	Global.selected_meat = meat_type

	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 1.1)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	get_tree().change_scene_to_file("res://scenes/CuttingStation.tscn")
