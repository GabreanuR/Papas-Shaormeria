extends TextureButton

func _ready() -> void:
	pressed.connect(_on_pressed)
	HealthInspection.cloth_state_changed.connect(_on_cloth_state_changed)


func _on_pressed() -> void:
	if HealthInspection.is_holding_cloth():
		HealthInspection.return_cloth()
	else:
		HealthInspection.pickup_cloth()


func _on_cloth_state_changed(is_holding: bool) -> void:
	modulate.a = 0.25 if is_holding else 1.0
	disabled = false
	visible = true
