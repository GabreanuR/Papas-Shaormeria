extends Node2D

@onready var fade_overlay: ColorRect = $FadeOverlay


func _ready():
	fade_overlay.position = Vector2.ZERO
	fade_overlay.size = get_viewport_rect().size

	fade_overlay.color = Color(0, 0, 0, 0.85)
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, 0.9)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
