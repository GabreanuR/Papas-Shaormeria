extends Sprite2D

@onready var meat_area = get_parent().get_node("Meat/Area2D")
@onready var cut_progress = get_parent().get_node("CutProgress")
@onready var result_label = get_parent().get_node("ResultLabel")

var meat_piece_scene = preload("res://scenes/cutting_station/MeatPiece.tscn")

var score := 0.0
var progress := 0.0
var visited_zones := []
var last_zone := -1
var finished := false

var blade_offset := Vector2(-45, -45)

# 🔽 NOU - control spawn
var spawn_cooldown := 0.0
var spawn_delay := 0.09

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

		# 🔽 spawn control
		if spawn_cooldown <= 0:
			spawn_meat_piece(blade_point)
			spawn_cooldown = spawn_delay

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

func spawn_meat_piece(spawn_position):
	var piece = meat_piece_scene.instantiate()
	get_parent().add_child(piece)
	piece.global_position = spawn_position

func finish_cutting():
	finished = true
	progress = 100
	cut_progress.value = 100

	var final_score = int(score)

	if final_score >= 180:
		result_label.text = "Perfect cut! Final score: " + str(final_score)
	elif final_score >= 100:
		result_label.text = "Good cut! Final score: " + str(final_score)
	else:
		result_label.text = "Bad cut! Final score: " + str(final_score)
