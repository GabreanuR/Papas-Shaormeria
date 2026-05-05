extends ColorRect

signal wrap_completed(quality: float)

@export var min_swipe_distance := 80.0

var start_pos: Vector2 = Vector2.ZERO
var is_dragging := false

var required_swipes := ["right", "left", "up"]
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
				var delta: Vector2 = event.position - start_pos

				if delta.length() >= min_swipe_distance:
					var direction := get_swipe_direction(delta)
					print("Directie:", direction)

					if current_swipe_index < required_swipes.size() and direction == required_swipes[current_swipe_index]:
						current_swipe_index += 1
						print("Corect:", current_swipe_index, "/", required_swipes.size())

						update_visual()

						if current_swipe_index >= required_swipes.size():
							var quality: float = max(0.0, 1.0 - mistakes * 0.2)
							print("WRAP COMPLET! Quality:", quality)
							wrap_completed.emit(quality)
							return
					else:
						print("Gresit -> reset")
						mistakes += 1
						reset_wrap()
				else:
					print("Swipe prea scurt")

			is_dragging = false

func get_swipe_direction(delta: Vector2) -> String:
	if abs(delta.x) > abs(delta.y):
		if delta.x > 0:
			return "right"
		else:
			return "left"
	else:
		if delta.y < 0:
			return "up"
		else:
			return "down"


func update_visual():
	var progress: float = float(current_swipe_index) / required_swipes.size()
	scale = Vector2(1.0 - 0.2 * progress, 1.0 - 0.1 * progress)


func reset_wrap():
	current_swipe_index = 0
	scale = Vector2.ONE
