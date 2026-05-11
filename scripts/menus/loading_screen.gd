extends Control

const TARGET_SCENE_PATH: String = "res://scenes/day_management/day_transition.tscn"
const MINIMUM_LOADING_TIME: float = 2.5

var _min_time_passed: bool = false
var _scene_is_ready: bool = false

var _tips: Array[String] = [
	"Tip: Angry customers calm down if they hear music on the radio.",
	"Tip: Don't forget to order pita bread before the storage runs out!",
	"Tip: High heat cooks meat faster, but you risk burning it.",
	"Tip: A good garlic sauce covers up a lot of mistakes.",
	"Tip: Clean tables often to maintain a good reputation in the neighborhood."
]

@onready var progress_bar: ProgressBar = %ProgressBar
@onready var tip_label: Label = %TipLabel
@onready var start_button: Button = %StartButton

func _ready() -> void:
	# Initialize UI state
	start_button.hide()
	progress_bar.value = 0.0
	tip_label.text = _tips.pick_random()
	
	# Connect signals
	start_button.pressed.connect(_on_start_pressed)
	
	# Safety Check: Ensure the scene exists before requesting it
	if not ResourceLoader.exists(TARGET_SCENE_PATH):
		push_error("CRITICAL ERROR: The scene does not exist at path: " + TARGET_SCENE_PATH)
		tip_label.text = "Error: Target scene not found!"
		set_process(false) # Stop _process to save resources
		return
		
	# Start asynchronous background loading
	ResourceLoader.load_threaded_request(TARGET_SCENE_PATH)
	
	# Start UX animation ("Fake Load")
	var tween: Tween = create_tween()
	tween.tween_property(progress_bar, "value", 100.0, MINIMUM_LOADING_TIME) \
		.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)
	
	# Flag the minimum time as passed once the animation finishes
	tween.finished.connect(func(): _min_time_passed = true)

func _process(_delta: float) -> void:
	# Poll the Godot engine for the actual loading status
	var status: int = ResourceLoader.load_threaded_get_status(TARGET_SCENE_PATH)
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		_scene_is_ready = true
	elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		push_error("ERROR: Threaded loading failed! Status code: " + str(status))
		tip_label.text = "Error: Threaded load failed."
		set_process(false)
		return
		
	# Proceed only if both the UX timer and actual engine loading are done
	if _min_time_passed and _scene_is_ready:
		_show_start_button()

func _show_start_button() -> void:
	# MAJOR OPTIMIZATION: Completely stop _process() to free up CPU cycles
	set_process(false)
	
	tip_label.text = "Loading complete!"
	progress_bar.hide()
	
	start_button.modulate.a = 0.0
	start_button.show()
	
	# Fade-in effect for the start button
	var tween: Tween = create_tween()
	tween.tween_property(start_button, "modulate:a", 1.0, 0.5)

func _on_start_pressed() -> void:
	# Retrieve the loaded scene from memory and switch to it
	var packed_scene: PackedScene = ResourceLoader.load_threaded_get(TARGET_SCENE_PATH)
	get_tree().change_scene_to_packed(packed_scene)
