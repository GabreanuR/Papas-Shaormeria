extends Control

# Scena reală a jocului (cea cu shaormeria/ziua)
const GAME_SCENE = "res://scenes/day_transition.tscn"

@onready var progress_bar = $ProgressBar
@onready var tip_label = $TipLabel
@onready var start_button = $StartButton

# O listă de sfaturi amuzante/utile pe care să le arătăm
var tips = [
	"Sfat: Clienții nervoși se calmează dacă aud muzică la radio.",
	"Sfat: Nu uita să comanzi lipii înainte să se termine stocul din depozit!",
	"Sfat: Focul mare gătește carnea repede, dar riști să o arzi.",
	"Sfat: Un sos de usturoi bun acoperă multe greșeli.",
	"Sfat: Curăță mesele des pentru a păstra o reputație bună în cartier."
]

func _ready():
	# Ascundem butonul de start la început
	start_button.hide()
	progress_bar.value = 0.0
	
	# Alegem un sfat la întâmplare
	tip_label.text = tips.pick_random()
	
	# Conectăm butonul de Start
	start_button.pressed.connect(_on_start_pressed)
	
	# --- ÎNCĂRCAREA REALĂ ÎN FUNDAL ---
	# Spunem motorului Godot să pregătească scena grea în memoria RAM
	ResourceLoader.load_threaded_request(GAME_SCENE)
	
	# --- ANIMAREA VIZUALĂ A BAREI (Fake Load pentru UX) ---
	# Facem o animație de 2.5 secunde ca jucătorul să apuce să citească sfatul
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", 100.0, 2.5)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	
	# Când ajunge bara la 100%, apelăm o funcție
	tween.chain().tween_callback(_on_loading_finished)

func _on_loading_finished():
	# Bara e plină. Schimbăm textul și afișăm butonul!
	tip_label.text = "Încărcare completă!"
	
	# Un mic efect de fade-in pentru butonul de START
	start_button.modulate.a = 0.0
	start_button.show()
	var tween = create_tween()
	tween.tween_property(start_button, "modulate:a", 1.0, 0.5)

func _on_start_pressed():
	# Când jucătorul dă click, preluăm scena încărcată din memorie și o rulăm!
	var packed_scene = ResourceLoader.load_threaded_get(GAME_SCENE)
	get_tree().change_scene_to_packed(packed_scene)
