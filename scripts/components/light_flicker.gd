extends PointLight2D

@export var flicker_speed: float = 3.0
@export var flicker_strength: float = 0.15
## How rapidly the noise pattern changes within each time step. Higher = more jittery flicker.
@export var noise_frequency: float = 100.0

var _noise: FastNoiseLite
var _base_energy: float
var _time_passed: float = 0.0

func _ready() -> void:
	_base_energy = energy
	
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.seed = randi()

func _process(delta: float) -> void:
	# Wrap with fmod to prevent float precision loss over very long sessions
	_time_passed = fmod(_time_passed + delta * flicker_speed, 1000.0)
	
	var noise_value: float = _noise.get_noise_1d(_time_passed * noise_frequency)
	
	energy = _base_energy + (noise_value * flicker_strength)

func turn_off() -> void:
	set_process(false)
	energy = 0.0

func turn_on() -> void:
	energy = _base_energy
	set_process(true)
