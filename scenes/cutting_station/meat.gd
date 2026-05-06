extends Node2D

@onready var sprite := $Sprite2D
@onready var background := $"../../TextureRect"

@onready var score_label := get_tree().current_scene.get_node_or_null("ScoreLabel")
@onready var result_label := get_tree().current_scene.get_node_or_null("ResultLabel")
@onready var progress_bar := get_tree().current_scene.get_node_or_null("CutProgress")

var chicken_texture := preload("res://assets/graphics/cutting_station/final_chick.png")
var beef_texture := preload("res://assets/graphics/cutting_station/final_beef.png")

var chicken_background := preload("res://assets/graphics/cutting_station/bg_chick.png")
var beef_background := preload("res://assets/graphics/cutting_station/bg_beef.png")


func _ready():
	if Global.selected_meat == "beef":
		sprite.texture = beef_texture
		background.texture = beef_background

		position = Vector2(870, 680)
		scale = Vector2(1.7, 1.7)

		# 🔹 SCORE
		if score_label:
			score_label.anchor_left = 0
			score_label.anchor_right = 0
			score_label.offset_left = 50
			score_label.offset_top = 150

		# 🔹 RESULT
		if result_label:
			result_label.anchor_left = 0
			result_label.anchor_right = 0
			result_label.offset_left = 50
			result_label.offset_top = 200

		# 🔹 PROGRESS BAR
		if progress_bar:
			progress_bar.anchor_left = 0
			progress_bar.anchor_right = 0
			progress_bar.offset_left = 50
			progress_bar.offset_top = 550
		
		
	else:
		sprite.texture = chicken_texture
		background.texture = chicken_background

		position = Vector2(980, 550)
		scale = Vector2(1.7, 1.7)

		if score_label:
			score_label.position = Vector2(900, 100)
		if result_label:
			result_label.position = Vector2(900, 150)
		if progress_bar:
			progress_bar.position = Vector2(900, 520)
