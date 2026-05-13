extends "res://scripts/gameplay/stations/assembly/ingredient.gd"

@export var scena_pata_sos: PackedScene
@export var culoare_sos: Color

func _get_drag_data(at_position):
	var data = super._get_drag_data(at_position)
	
	data["este_sos"] = true
	data["scena_pata"] = preload("res://scenes/gameplay/stations/assembly/assembly_station.tscn")
	data["culoare"] = culoare_sos
	
	return data
