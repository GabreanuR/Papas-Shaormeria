extends ColorRect

signal fade_in_finished
signal fade_out_finished

@export var default_alpha: float = 0.85
@export var default_fade_time: float = 0.5

var _fade_tween: Tween

func _ready() -> void:
	# Ensure it starts completely invisible and ignores mouse clicks when hidden
	modulate.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()

func fade_in(target_alpha: float = default_alpha, duration: float = default_fade_time) -> void:
	show()
	# Block clicks from passing through to buttons behind the overlay
	mouse_filter = Control.MOUSE_FILTER_STOP
	_play_fade(target_alpha, duration)
	
	# Capture the tween created by _play_fade. If a new fade interrupts this one,
	# _play_fade will kill this tween and replace _fade_tween — a killed tween
	# never emits 'finished', so we must guard against emitting stale signals.
	var tween := _fade_tween
	await tween.finished
	if _fade_tween == tween:
		fade_in_finished.emit()

func fade_out(duration: float = default_fade_time) -> void:
	# Let clicks pass through again so the user can interact with the menu
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_play_fade(0.0, duration)
	
	var tween := _fade_tween
	await tween.finished
	if _fade_tween == tween:
		hide()
		fade_out_finished.emit()

func fade_to_full_black(duration: float = 1.0) -> void:
	# Delegates to fade_in at full opacity — avoids duplicating await/signal logic
	await fade_in(1.0, duration)

func _play_fade(target_a: float, duration: float) -> void:
	# Kill any existing fade to prevent visual glitches if clicked rapidly
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
		
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", target_a, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
