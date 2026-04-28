extends "res://scripts/assemble_ingredients/ingredient.gd"

@export var scena_pata_sos: PackedScene
@export var culoare_sos: Color

func _get_drag_data(at_position):
	var data = super._get_drag_data(at_position)
	
	data["este_sos"] = true
	data["scena_pata"] = scena_pata_sos
	data["culoare"] = culoare_sos
	
	return data
