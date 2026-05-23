extends ColorRect

signal wrap_step_changed(step_index: int)
signal wrap_completed(quality: float)

@export var min_swipe_distance := 80.0
@export var required_swipes: Array[String] = ["right", "left", "up", "up"]

var start_pos: Vector2 = Vector2.ZERO
var is_dragging := false
var current_swipe_index := 0
var mistakes := 0

func _input(event):
	if current_swipe_index >= required_swipes.size():
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_pos = event.position
			is_dragging = true
		else:
			if is_dragging:
				_handle_swipe(event.position - start_pos)

			is_dragging = false

func _handle_swipe(delta: Vector2) -> void:
	if delta.length() < min_swipe_distance:
		return

	var direction := get_swipe_direction(delta)

	if direction == required_swipes[current_swipe_index]:
		current_swipe_index += 1
		wrap_step_changed.emit(current_swipe_index - 1)

		if current_swipe_index >= required_swipes.size():
			var quality: float = max(0.0, 1.0 - mistakes * 0.2)
			wrap_completed.emit(quality)
	else:
		mistakes += 1
		reset_wrap()

func get_swipe_direction(delta: Vector2) -> String:
	if abs(delta.x) > abs(delta.y):
		return "right" if delta.x > 0 else "left"
	else:
		return "up" if delta.y < 0 else "down"

func reset_wrap() -> void:
	current_swipe_index = 0
	wrap_step_changed.emit(-1)
