extends Control

@export var multipliers: Array[float] = [0.005, 0.01, 0.005, 0.02, 0.0]

var _base_positions: Array[Vector2] = []
var _screen_center: Vector2

@onready var parallax_layers: Array[Node] = get_children()

func _ready() -> void:
	await get_tree().process_frame
	
	_update_screen_data()
	
	if not get_viewport().size_changed.is_connected(_update_screen_data):
		get_viewport().size_changed.connect(_update_screen_data)

func _process(delta: float) -> void:
	var mouse_pos := get_global_mouse_position()
	var offset := mouse_pos - _screen_center
	
	for i in range(parallax_layers.size()):
		if i < multipliers.size():
			var layer := parallax_layers[i] as Control
			if layer:
				var target_position: Vector2 = _base_positions[i] - (offset * multipliers[i])
				layer.position = layer.position.lerp(target_position, 5.0 * delta)

func _update_screen_data() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	_screen_center = get_viewport_rect().size / 2.0
	_base_positions.clear() 
	
	for layer in parallax_layers:
		if layer is Control:
			layer.set_anchors_preset(Control.PRESET_TOP_LEFT)
			layer.pivot_offset = layer.size / 2.0
			var base_pos: Vector2 = _screen_center - (layer.size / 2.0)
			_base_positions.append(base_pos)
			layer.position = base_pos
			
