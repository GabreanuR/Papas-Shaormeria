extends Control

const GAME_SCENE = "res://scenes/menus/day_transition.tscn"

@onready var progress_bar = %ProgressBar
@onready var tip_label = %TipLabel
@onready var start_button = %StartButton

var tips = [
	"Tip: Angry customers calm down if they hear music on the radio.",
	"Tip: Don't forget to order pita bread before the storage runs out!",
	"Tip: High heat cooks meat faster, but you risk burning it.",
	"Tip: A good garlic sauce covers up a lot of mistakes.",
	"Tip: Clean tables often to maintain a good reputation in the neighborhood."
]

var min_time_passed: bool = false
var scene_is_ready: bool = false
var is_button_shown: bool = false

func _ready():
	start_button.hide()
	progress_bar.value = 0.0
	tip_label.text = tips.pick_random()
	start_button.pressed.connect(_on_start_pressed)
	
	# --- SAFETY CHECK ---
	# Verificăm dacă scena chiar există înainte să îi cerem motorului să o încarce
	if not ResourceLoader.exists(GAME_SCENE):
		print("CRITICAL ERROR: The scene does not exist at path: ", GAME_SCENE)
		tip_label.text = "Error: Target scene not found!"
		return
	
	ResourceLoader.load_threaded_request(GAME_SCENE)
	
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", 100.0, 2.5)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	
	tween.finished.connect(func(): min_time_passed = true)

func _process(_delta: float) -> void:
	if is_button_shown:
		return
		
	var status = ResourceLoader.load_threaded_get_status(GAME_SCENE)
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		scene_is_ready = true
	elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		print("ERROR: Threaded loading failed! Status: ", status)
		tip_label.text = "Error: Threaded load failed."
		set_process(false)
		return
		
	if min_time_passed and scene_is_ready:
		_show_start_button()

func _show_start_button():
	is_button_shown = true
	tip_label.text = "Loading complete!"
	
	progress_bar.hide()
	
	start_button.modulate.a = 0.0
	start_button.show()
	var tween = create_tween()
	tween.tween_property(start_button, "modulate:a", 1.0, 0.5)

func _on_start_pressed():
	var packed_scene = ResourceLoader.load_threaded_get(GAME_SCENE)
	get_tree().change_scene_to_packed(packed_scene)
