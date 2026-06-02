extends "res://scripts/gameplay/stations/assembly/ingredient.gd"

@export var nume_sos: String
@export var scena_pata_sos: PackedScene = preload("res://scenes/gameplay/stations/assembly/pata_sos.tscn")
@export var culoare_sos: Color

func _get_drag_data(at_position):
	var data = super._get_drag_data(at_position)

	data["este_sos"] = true
	data["scena_pata"] = scena_pata_sos
	data["culoare"] = culoare_sos
	data["nume"] = nume_sos

	var preview = TextureRect.new()
	preview.texture = texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.size = size
	preview.add_to_group("sauce_drag_preview")
	set_drag_preview(preview)

	return data
