extends CanvasLayer

@onready var panel: PanelContainer = $PanelContainer
@onready var info_label: Label = $PanelContainer/VBoxContainer/InfoLabel
@onready var timer_label: Label = $PanelContainer/VBoxContainer/TimerLabel
@onready var penalty_label: Label = $PanelContainer/VBoxContainer/PenaltyLabel
@onready var status_label: Label = $PanelContainer/VBoxContainer/StatusLabel
@onready var mouse_cloth: TextureRect = $MouseCloth
@onready var vbox: VBoxContainer = $PanelContainer/VBoxContainer

var normal_color := Color.WHITE
var warning_color := Color.RED
var success_color := Color(0.2, 1.0, 0.2, 1.0)


func _ready() -> void:
	panel.visible = false
	mouse_cloth.visible = false
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	penalty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_cloth.mouse_filter = Control.MOUSE_FILTER_IGNORE

	HealthInspection.inspection_started.connect(_on_inspection_started)
	HealthInspection.inspection_finished.connect(_on_inspection_finished)
	HealthInspection.timer_updated.connect(_on_timer_updated)
	HealthInspection.penalty_updated.connect(_on_penalty_updated)
	HealthInspection.cloth_state_changed.connect(_on_cloth_state_changed)
	HealthInspection.mess_cleaned_successfully.connect(_on_mess_cleaned_successfully)

func _process(_delta: float) -> void:
	if mouse_cloth.visible:
		mouse_cloth.global_position = mouse_cloth.get_global_mouse_position() - mouse_cloth.size / 2.0


func _on_inspection_started() -> void:
	panel.visible = true

	info_label.visible = true
	timer_label.visible = true
	penalty_label.visible = true
	status_label.visible = false

	info_label.text = "Time left for cleaning the mess before penalties are applied:"
	timer_label.text = "01:00"
	penalty_label.text = ""

	timer_label.add_theme_color_override("font_color", normal_color)
	penalty_label.add_theme_color_override("font_color", warning_color)


func _on_inspection_finished() -> void:
	info_label.visible = false
	timer_label.visible = false
	penalty_label.visible = false


func _on_timer_updated(time_left: float) -> void:
	var seconds := int(ceil(time_left))
	var minutes := seconds / 60
	var rest_seconds := seconds % 60

	timer_label.text = "%02d:%02d" % [minutes, rest_seconds]

	if time_left <= 15.0:
		timer_label.add_theme_color_override("font_color", warning_color)
	else:
		timer_label.add_theme_color_override("font_color", normal_color)


func _on_penalty_updated(total_penalty: int) -> void:
	if total_penalty <= 0:
		penalty_label.text = ""
	else:
		penalty_label.text = "-$%d" % total_penalty
		penalty_label.add_theme_color_override("font_color", warning_color)


func _on_cloth_state_changed(is_holding: bool) -> void:
	mouse_cloth.visible = is_holding


func _on_mess_cleaned_successfully() -> void:
	if not is_inside_tree():
		return

	panel.visible = true

	info_label.visible = false
	timer_label.visible = false
	penalty_label.visible = false

	status_label.visible = true
	status_label.text = "Cleaned the mess!"
	status_label.add_theme_color_override("font_color", success_color)

	var tree := get_tree()
	if tree == null:
		return

	await tree.create_timer(4.0).timeout

	if not is_inside_tree():
		return

	status_label.visible = false
	panel.visible = false
