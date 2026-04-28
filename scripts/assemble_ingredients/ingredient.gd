extends TextureRect

@export var nume_ingredient: String = "Cartofi"

func _get_drag_data(at_position):
	var preview = TextureRect.new()
	preview.texture = texture
	var control = Control.new()
	control.add_child(preview)
	preview.position = -texture.get_size() / 2
	set_drag_preview(control)
	
	return {"nume": nume_ingredient, "poza": texture}
