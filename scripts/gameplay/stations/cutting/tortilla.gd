extends Area2D

var heat_state: String = "raw"
var has_meat: bool = false
var meat_type: String = ""
var meat_quality: String = "good"
var cutting_score: int = 0

@onready var sprite: Sprite2D = $Sprite2D
@onready var meat_container: Node2D = $MeatContainer


func setup() -> void:
	visible = true
	heat_state = "raw"
	has_meat = false
	meat_type = ""
	meat_quality = "good"
	cutting_score = 0
	remove_glow()
	sprite.modulate = Color.WHITE


func mark_heating() -> void:
	heat_state = "heating"
	remove_glow()


func mark_ready() -> void:
	heat_state = "ready"
	add_glow()


func mark_burned() -> void:
	heat_state = "burned"
	remove_glow()
	sprite.modulate = Color(0.45, 0.25, 0.12)


func add_meat(new_meat_type: String, new_meat_quality: String, meat_texture: Texture2D) -> void:
	if has_meat:
		return

	has_meat = true
	meat_type = new_meat_type
	meat_quality = new_meat_quality

	var meat_sprite: Sprite2D = Sprite2D.new()
	meat_sprite.name = "MeatSprite"
	meat_sprite.texture = meat_texture
	meat_sprite.scale = Vector2(0.08, 0.08)
	meat_container.add_child(meat_sprite)


func add_glow() -> void:
	if has_node("GlowOutline"):
		return

	var glow: Sprite2D = Sprite2D.new()
	glow.name = "GlowOutline"
	glow.texture = sprite.texture
	glow.scale = sprite.scale * 1.18
	glow.modulate = Color(1.0, 0.9, 0.25, 0.55)
	glow.z_index = sprite.z_index - 1

	add_child(glow)
	move_child(glow, 0)


func remove_glow() -> void:
	var glow: Node = get_node_or_null("GlowOutline")
	if glow != null:
		glow.queue_free()
