extends CanvasLayer

signal shutter_closed

const ANIM_CLOSE: StringName = &"close"

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var shutter_sfx: AudioStreamPlayer = $ShutterSFX

func close_shutter() -> void:
	if animation_player.is_playing():
		return
	animation_player.play(ANIM_CLOSE)
	shutter_sfx.play()

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == ANIM_CLOSE:
		shutter_closed.emit()
