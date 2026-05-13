extends TextureButton
class_name AnimatedMenuButton

@export_group("Hover Animation")
@export var hover_scale: Vector2 = Vector2(1.05, 1.05)
@export var hover_modulate: Color = Color(0.8, 0.8, 0.8, 1.0)
@export var animation_speed: float = 0.15

var _base_scale: Vector2
var _base_modulate: Color
var _tween: Tween

func _ready() -> void:
	# Store initial values
	_base_scale = scale
	_base_modulate = modulate
	
	# Set pivot to center for better scaling
	pivot_offset = size / 2.0
	
	# Connect signals
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)
	
	# Handle dynamic position if in a container
	resized.connect(_update_pivot)

func _update_pivot() -> void:
	pivot_offset = size / 2.0

func _animate(target_scale: Vector2, target_modulate: Color, speed: float) -> void:
	if _tween: _tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.set_ease(Tween.EASE_OUT)
	
	_tween.tween_property(self, "scale", target_scale, speed)
	_tween.tween_property(self, "modulate", target_modulate, speed)

func _on_hover() -> void:
	if disabled: return
	_animate(hover_scale, hover_modulate, animation_speed)

func _on_unhover() -> void:
	if disabled: return
	_animate(_base_scale, _base_modulate, animation_speed)
