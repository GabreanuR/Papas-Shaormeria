extends TextureRect

@export var nume_ingredient: String = "Cartofi"
@export var textura_shaorma: Texture2D

func _get_drag_data(at_position):
	var preview = TextureRect.new()
	
	if textura_shaorma:
		preview.texture = textura_shaorma
	else:
		preview.texture = texture
		
	preview.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	
	var control = Control.new()
	control.add_child(preview)
	preview.position = -preview.texture.get_size() / 2
	set_drag_preview(control)
	
	return {
			"nume": nume_ingredient, 
			"poza": texture, 
			"poza_shaorma": textura_shaorma 
	}
