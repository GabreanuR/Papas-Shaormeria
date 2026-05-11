extends CanvasLayer

signal shutter_closed

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var shutter_sfx: AudioStreamPlayer = $ShutterSFX

func close_shutter() -> void:
	animation_player.play("close")
	shutter_sfx.play()

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "close":
		shutter_closed.emit()
