extends PointLight2D

@export var flicker_speed: float = 3.0
@export var flicker_strength: float = 0.15

var _noise: FastNoiseLite
var _base_energy: float
var _time_passed: float = 0.0

func _ready() -> void:
	_base_energy = energy
	
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.seed = randi()

func _process(delta: float) -> void:
	_time_passed += delta * flicker_speed
	
	var noise_value: float = _noise.get_noise_1d(_time_passed * 100.0)
	
	energy = _base_energy + (noise_value * flicker_strength)

func fade_out(tween: Tween, duration: float) -> void:
	set_process(false)
	tween.tween_property(self, "energy", 0.0, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

func fade_in(tween: Tween, duration: float) -> void:
	tween.tween_property(self, "energy", _base_energy, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

func resume_flicker() -> void:
	set_process(true)
