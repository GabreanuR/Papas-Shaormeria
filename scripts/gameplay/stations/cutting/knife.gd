extends Sprite2D

@onready var meat_area = get_parent().get_node("Meat/Area2D")
@onready var cut_progress = get_parent().get_node("CutProgress")
@onready var result_label = get_parent().get_node("ResultLabel")

var score := 0.0
var progress := 0.0
var visited_zones := []
var last_zone := -1
var finished := false

@export var blade_offset := Vector2(-45, -45)

var spawn_cooldown := 0.0
var spawn_delay := 0.09

const SCORE_PERFECT_THRESHOLD := 180
const SCORE_GOOD_THRESHOLD := 100


func _ready():
	cut_progress.min_value = 0
	cut_progress.max_value = 100
	cut_progress.value = 0
	result_label.text = "Hold click and slice the meat!"


func _process(delta):
	if finished:
		return

	spawn_cooldown -= delta

	position = get_global_mouse_position()
	var blade_point = global_position + blade_offset

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		check_cutting(blade_point)


func check_cutting(blade_point):
	var shape = meat_area.get_node("CollisionShape2D").shape
	var meat_pos = meat_area.global_position

	var meat_rect = Rect2(
		meat_pos - shape.size / 2,
		shape.size
	)

	if meat_rect.has_point(blade_point):
		var local_y = blade_point.y - meat_rect.position.y
		var zone_height = meat_rect.size.y / 5
		var zone = int(local_y / zone_height)

		score += 2

		if zone != last_zone:
			progress += 2.0
			score += 5
			last_zone = zone
		else:
			progress += 0.5

		if not visited_zones.has(zone):
			visited_zones.append(zone)
			score += 10
	else:
		score -= 0.2

	cut_progress.value = progress

	if progress >= 100:
		finish_cutting()


func finish_cutting():
	finished = true
	progress = 100
	cut_progress.value = 100

	var final_score = max(int(score), 0)

	if final_score >= SCORE_PERFECT_THRESHOLD:
		result_label.text = "Perfect cut! Final score: " + str(final_score)
	elif final_score >= SCORE_GOOD_THRESHOLD:
		result_label.text = "Good cut! Final score: " + str(final_score)
	else:
		result_label.text = "Bad cut! Final score: " + str(final_score)

	var gameplay_master = get_tree().current_scene

	if gameplay_master and "current_pita_state" in gameplay_master:
		gameplay_master.current_pita_state["is_cut"] = true

	if gameplay_master and gameplay_master.has_method("update_station_score"):
		gameplay_master.update_station_score("cutting", final_score)

	await get_tree().create_timer(1.5).timeout

	var cutting_station = get_parent().get_parent()
	cutting_station.queue_free()

	var meat_select = gameplay_master.get_node_or_null("MeatSelect")
	if meat_select and meat_select.has_method("reset_meat_select"):
		meat_select.reset_meat_select()

	if gameplay_master and gameplay_master.has_method("_go_to_assembly"):
		gameplay_master._go_to_assembly()
