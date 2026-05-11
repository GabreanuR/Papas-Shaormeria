extends Control

const TARGET_SCENE_PATH: String = "res://scenes/day_management/day_transition.tscn"
const MINIMUM_LOADING_TIME: float = 2.5

var _min_time_passed: bool = false
var _scene_is_ready: bool = false
var _loading_finished: bool = false

var _tips: Array[String] = [
	"Angry customers calm down if they hear music on the radio.",
	"Don't forget to order pita bread before the storage runs out!",
	"High heat cooks meat faster, but you risk burning it.",
	"A good garlic sauce covers up a lot of mistakes.",
	"Clean tables often to maintain a good reputation in the neighborhood."
]

@onready var progress_bar: ProgressBar = %ProgressBar
@onready var tip_label: Label = %TipLabel
@onready var start_button: Button = %StartButton

func _ready() -> void:
	# Initialize UI state
	start_button.hide()
	progress_bar.value = 0.0
	tip_label.text = "Tip: " + _tips.pick_random()
	
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
	# Cap at 95 — the bar will snap to 100 only when the real load confirms done
	tween.tween_property(progress_bar, "value", 95.0, MINIMUM_LOADING_TIME) \
		.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)
	
	# Flag the minimum time as passed once the animation finishes
	tween.finished.connect(func(): _min_time_passed = true)

func _process(_delta: float) -> void:
	# Only poll the engine while the scene isn't confirmed loaded yet
	if not _scene_is_ready:
		var status: int = ResourceLoader.load_threaded_get_status(TARGET_SCENE_PATH)
		
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			_scene_is_ready = true
			# Snap the bar to 100% now that the real load is confirmed
			progress_bar.value = 100.0
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("ERROR: Threaded loading failed! Status code: " + str(status))
			tip_label.text = "Error: Threaded load failed."
			set_process(false)
			return
	
	# Proceed only if both the UX timer and actual engine loading are done.
	# _loading_finished guards against this being called more than once.
	if _min_time_passed and _scene_is_ready and not _loading_finished:
		_loading_finished = true
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
	# Prevent double-press during the fade
	start_button.disabled = true
	
	# Fade the whole screen to black, then switch scenes
	var fade := ColorRect.new()
	fade.color = Color(0.0, 0.0, 0.0, 0.0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fade)
	
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.4)
	await tween.finished
	
	# Retrieve the already-loaded scene from memory and switch to it
	var packed_scene: PackedScene = ResourceLoader.load_threaded_get(TARGET_SCENE_PATH)
	get_tree().change_scene_to_packed(packed_scene)
