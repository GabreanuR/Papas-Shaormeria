extends PointLight2D

# Variabile pe care le poți modifica direct din Inspector (în dreapta ecranului)
@export var flicker_speed: float = 3.0
@export var flicker_strength: float = 0.15

var noise: FastNoiseLite
var base_energy: float
var time_passed: float = 0.0

func _ready():
	# Salvăm energia inițială a luminii pe care ai setat-o în editor
	base_energy = energy
	
	# Creăm generatorul de zgomot (pentru o tranziție fluidă, nu bruscă)
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	
	# Îi dăm un seed aleatoriu, astfel încât dacă ai 3 lumini,
	# să nu pâlpâie toate 3 perfect sincronizat.
	noise.seed = randi()

func _process(delta):
	# Timpul trece...
	time_passed += delta * flicker_speed
	
	# get_noise_1d ne dă o valoare fină între -1.0 și 1.0
	var noise_value = noise.get_noise_1d(time_passed * 100.0)
	
	# Calculăm noua energie: Baza + (Zgomot * Forță)
	energy = base_energy + (noise_value * flicker_strength)
