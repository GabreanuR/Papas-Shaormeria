extends Node2D

var velocity := Vector2.ZERO
var gravity := 520.0
var rotation_speed := 0.0

func _ready():
	velocity = Vector2(
		randf_range(-120.0, 120.0),
		randf_range(60.0, 170.0)
	)

	rotation_speed = randf_range(-7.0, 7.0)
	rotation = randf_range(-0.8, 0.8)

	# bucăți mai mari
	scale = Vector2.ONE * randf_range(1.1, 1.7)

	# juicy look: culoare ușor random, mai roșiatică
	modulate = Color(
		randf_range(0.9, 1.0),
		randf_range(0.25, 0.45),
		randf_range(0.18, 0.28),
		1.0
	)

func _process(delta):
	velocity.y += gravity * delta
	position += velocity * delta
	rotation += rotation_speed * delta

	# se micșorează puțin când cade
	scale *= 0.995

	if position.y > 850:
		queue_free()
