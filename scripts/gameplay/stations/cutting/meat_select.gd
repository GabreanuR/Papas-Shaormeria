extends Node2D

@export var tortilla_texture: Texture2D
@export var meat_chicken_texture: Texture2D
@export var meat_beef_texture: Texture2D
@export var mess_texture: Texture2D

@export var indicator_light: Texture2D
@export var indicator_medium: Texture2D
@export var indicator_burned: Texture2D

const TORTILLA_HEAT_TIME := 20.0
const TORTILLA_BURN_TIME := 30.0
const MEAT_BURN_TIME := 40.0

@onready var tortilla_stack: Area2D = $TortillaStack
@onready var tortilla_spawn_point: Marker2D = $TortillaStack/SpawnPoint

@onready var tortillas_container: Node2D = $SpawnedObjects/Tortillas
@onready var meat_pieces_container: Node2D = $"SpawnedObjects/Meat Pieces"

@onready var chicken_cut_area: Area2D = $RecognitionAreas/ChickenCutArea
@onready var beef_cut_area: Area2D = $RecognitionAreas/BeefCutArea

@onready var chicken_drop_point: Marker2D = $MeatDropPoints/ChickenDropPoint
@onready var beef_drop_point: Marker2D = $MeatDropPoints/BeefDropPoint

@onready var chicken_indicator: Sprite2D = $MeatCookingIndicators/ChickenIndicator
@onready var beef_indicator: Sprite2D = $MeatCookingIndicators/BeefIndicator

@onready var knife: Area2D = $Knife

@onready var grill_slots: Node2D = $GrillSlots
@onready var heated_area: Area2D = $TortillaDropAreas/HeatedTortillaArea
@onready var filling_area: Area2D = $TortillaDropAreas/FillingArea

@onready var trash_zone: Area2D = $DropZones/TrashZone
@onready var send_zone: Area2D = $DropZones/SendToAssemblyZone

@onready var mess_container: Node2D = $MessContainer
@onready var drag_layer: Node2D = $DragLayer

var dragged_object: Area2D = null
var drag_offset := Vector2.ZERO

var grill_data := {}
var heated_tortillas: Array[Area2D] = []
var filling_tortilla: Area2D = null

var chicken_cook_time := 0.0
var beef_cook_time := 0.0

var cutting_score_data := {
	"burned_tortillas": 0,
	"burned_meat": 0,
	"mess": 0,
	"good_meat": 0,
	"sent_shaormas": 0
}


func _ready() -> void:
	tortilla_stack.input_event.connect(_on_tortilla_stack_input)

	for slot in grill_slots.get_children():
		if slot is Area2D:
			grill_data[slot] = {
				"tortilla": null,
				"heat_time": 0.0
			}

	make_draggable(knife)


func _process(delta: float) -> void:
	update_dragged_object()
	update_grill(delta)
	update_meat_cooking(delta)
	check_knife_cutting()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if dragged_object != null:
				handle_drop(dragged_object)
				dragged_object = null


func _on_tortilla_stack_input(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var tortilla := create_tortilla()
			start_drag(tortilla)


func create_tortilla() -> Area2D:
	var tortilla := Area2D.new()
	tortilla.name = "Tortilla"
	tortilla.global_position = tortilla_spawn_point.global_position
	tortilla.set_meta("object_type", "tortilla")
	tortilla.set_meta("heat_state", "raw")
	tortilla.set_meta("has_meat", false)
	tortilla.set_meta("meat_type", "")
	tortilla.set_meta("meat_quality", "")
	tortilla.set_meta("cutting_score", 0)

	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = tortilla_texture
	sprite.scale = Vector2(0.18, 0.18)
	tortilla.add_child(sprite)

	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := CircleShape2D.new()
	shape.radius = 55
	collision.shape = shape
	tortilla.add_child(collision)

	var meat_container := Node2D.new()
	meat_container.name = "MeatContainer"
	tortilla.add_child(meat_container)

	tortillas_container.add_child(tortilla)
	make_draggable(tortilla)

	return tortilla


func create_meat_piece(meat_type: String, position_to_spawn: Vector2) -> Area2D:
	var piece := Area2D.new()
	piece.name = meat_type.capitalize() + "MeatPiece"
	piece.global_position = position_to_spawn
	piece.set_meta("object_type", "meat")
	piece.set_meta("meat_type", meat_type)

	var quality := get_meat_quality(meat_type)
	piece.set_meta("meat_quality", quality)

	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"

	if meat_type == "chicken":
		sprite.texture = meat_chicken_texture
	else:
		sprite.texture = meat_beef_texture

	sprite.scale = Vector2(0.12, 0.12)
	piece.add_child(sprite)

	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := CircleShape2D.new()
	shape.radius = 35
	collision.shape = shape
	piece.add_child(collision)

	meat_pieces_container.add_child(piece)
	make_draggable(piece)

	return piece


func make_draggable(obj: Area2D) -> void:
	if obj.input_event.is_connected(_on_draggable_input):
		return

	obj.input_event.connect(_on_draggable_input.bind(obj))


func _on_draggable_input(_viewport, event, _shape_idx, obj: Area2D) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			start_drag(obj)


func start_drag(obj: Area2D) -> void:
	dragged_object = obj
	drag_offset = obj.global_position - get_global_mouse_position()

	if obj.get_parent() != drag_layer:
		obj.reparent(drag_layer, true)


func update_dragged_object() -> void:
	if dragged_object != null:
		dragged_object.global_position = get_global_mouse_position() + drag_offset


func handle_drop(obj: Area2D) -> void:
	var object_type: String = obj.get_meta("object_type", "")

	if is_inside_area(obj.global_position, trash_zone):
		obj.queue_free()
		return

	if object_type == "tortilla":
		handle_tortilla_drop(obj)
	elif object_type == "meat":
		handle_meat_drop(obj)


func handle_tortilla_drop(tortilla: Area2D) -> void:
	var free_grill_slot := get_free_grill_slot_at_position(tortilla.global_position)

	if free_grill_slot != null:
		place_tortilla_on_grill(tortilla, free_grill_slot)
		return

	if is_inside_area(tortilla.global_position, heated_area):
		place_tortilla_in_heated_area(tortilla)
		return

	if is_inside_area(tortilla.global_position, filling_area):
		place_tortilla_in_filling_area(tortilla)
		return

	if is_inside_area(tortilla.global_position, send_zone):
		send_tortilla_to_assembly(tortilla)
		return


func handle_meat_drop(meat: Area2D) -> void:
	if filling_tortilla != null and is_inside_area(meat.global_position, filling_area):
		add_meat_to_tortilla(meat, filling_tortilla)
	else:
		create_mess(meat.global_position)
		meat.queue_free()


func get_free_grill_slot_at_position(pos: Vector2) -> Area2D:
	for slot in grill_data.keys():
		if is_inside_area(pos, slot) and grill_data[slot]["tortilla"] == null:
			return slot

	return null


func place_tortilla_on_grill(tortilla: Area2D, slot: Area2D) -> void:
	var anchor := slot.get_node("TortillaAnchor") as Marker2D

	tortilla.reparent(tortillas_container, true)
	tortilla.global_position = anchor.global_position

	grill_data[slot]["tortilla"] = tortilla
	grill_data[slot]["heat_time"] = 0.0

	tortilla.set_meta("heat_state", "heating")
	remove_glow(tortilla)


func place_tortilla_in_heated_area(tortilla: Area2D) -> void:
	var heat_state: String = tortilla.get_meta("heat_state", "raw")

	if heat_state != "ready":
		return

	tortilla.reparent(tortillas_container, true)

	var anchor := get_next_heated_anchor()
	if anchor != null:
		tortilla.global_position = anchor.global_position

	if not heated_tortillas.has(tortilla):
		heated_tortillas.append(tortilla)


func place_tortilla_in_filling_area(tortilla: Area2D) -> void:
	if filling_tortilla != null:
		return

	var heat_state: String = tortilla.get_meta("heat_state", "raw")
	if heat_state != "ready":
		return

	var anchor := filling_area.get_node("TortillaAnchor") as Marker2D

	tortilla.reparent(tortillas_container, true)
	tortilla.global_position = anchor.global_position

	filling_tortilla = tortilla
	heated_tortillas.erase(tortilla)


func add_meat_to_tortilla(meat: Area2D, tortilla: Area2D) -> void:
	if tortilla.get_meta("has_meat", false):
		meat.queue_free()
		return

	var meat_type: String = meat.get_meta("meat_type", "")
	var meat_quality: String = meat.get_meta("meat_quality", "good")

	tortilla.set_meta("has_meat", true)
	tortilla.set_meta("meat_type", meat_type)
	tortilla.set_meta("meat_quality", meat_quality)

	var meat_sprite := Sprite2D.new()
	meat_sprite.name = "MeatSprite"

	if meat_type == "chicken":
		meat_sprite.texture = meat_chicken_texture
	else:
		meat_sprite.texture = meat_beef_texture

	meat_sprite.scale = Vector2(0.08, 0.08)
	meat_sprite.position = Vector2.ZERO

	tortilla.get_node("MeatContainer").add_child(meat_sprite)

	if meat_quality == "burned":
		cutting_score_data["burned_meat"] += 1
	else:
		cutting_score_data["good_meat"] += 1

	meat.queue_free()


func send_tortilla_to_assembly(tortilla: Area2D) -> void:
	if not tortilla.get_meta("has_meat", false):
		return

	var tortilla_data := {
		"lipie_quality": tortilla.get_meta("heat_state", "raw"),
		"meat_type": tortilla.get_meta("meat_type", ""),
		"meat_quality": tortilla.get_meta("meat_quality", ""),
		"cutting_score": calculate_tortilla_score(tortilla)
	}

	cutting_score_data["sent_shaormas"] += 1

	var master := get_node_or_null("/root/GameplayMaster")
	if master != null:
		if not master.has_meta("prepared_shaormas_queue"):
			master.set_meta("prepared_shaormas_queue", [])

		var queue: Array = master.get_meta("prepared_shaormas_queue")
		queue.append(tortilla_data)
		master.set_meta("prepared_shaormas_queue", queue)

	if filling_tortilla == tortilla:
		filling_tortilla = null

	heated_tortillas.erase(tortilla)
	tortilla.queue_free()


func calculate_tortilla_score(tortilla: Area2D) -> int:
	var score := 100

	if tortilla.get_meta("heat_state", "") == "burned":
		score -= 25

	if tortilla.get_meta("meat_quality", "") == "burned":
		score -= 35

	score -= cutting_score_data["mess"] * 5

	return clamp(score, 0, 100)


func update_grill(delta: float) -> void:
	for slot in grill_data.keys():
		var tortilla: Area2D = grill_data[slot]["tortilla"]

		if tortilla == null:
			continue

		grill_data[slot]["heat_time"] += delta
		var heat_time: float = grill_data[slot]["heat_time"]

		var timer_circle: TextureProgressBar = slot.get_node_or_null("HeatTimerCircle")
		if timer_circle != null and timer_circle is TextureProgressBar:
			timer_circle.value = clamp((heat_time / TORTILLA_HEAT_TIME) * 100.0, 0.0, 100.0)

		if heat_time >= TORTILLA_HEAT_TIME and tortilla.get_meta("heat_state", "") == "heating":
			tortilla.set_meta("heat_state", "ready")
			add_glow(tortilla)

		if heat_time >= TORTILLA_BURN_TIME and tortilla.get_meta("heat_state", "") != "burned":
			tortilla.set_meta("heat_state", "burned")
			cutting_score_data["burned_tortillas"] += 1
			remove_glow(tortilla)

			var sprite := tortilla.get_node("Sprite2D") as Sprite2D
			sprite.modulate = Color(0.45, 0.25, 0.12)


func add_glow(tortilla: Area2D) -> void:
	if tortilla.has_node("GlowOutline"):
		return

	var base_sprite := tortilla.get_node("Sprite2D") as Sprite2D

	var glow := Sprite2D.new()
	glow.name = "GlowOutline"
	glow.texture = base_sprite.texture
	glow.scale = base_sprite.scale * 1.18
	glow.modulate = Color(1.0, 0.9, 0.25, 0.55)
	glow.z_index = base_sprite.z_index - 1

	tortilla.add_child(glow)
	tortilla.move_child(glow, 0)


func remove_glow(tortilla: Area2D) -> void:
	var glow := tortilla.get_node_or_null("GlowOutline")
	if glow != null:
		glow.queue_free()


func update_meat_cooking(delta: float) -> void:
	chicken_cook_time += delta
	beef_cook_time += delta

	update_meat_indicator("chicken")
	update_meat_indicator("beef")


func update_meat_indicator(meat_type: String) -> void:
	var cook_time := chicken_cook_time
	var indicator := chicken_indicator

	if meat_type == "beef":
		cook_time = beef_cook_time
		indicator = beef_indicator

	if cook_time < MEAT_BURN_TIME * 0.5:
		indicator.texture = indicator_light
	elif cook_time < MEAT_BURN_TIME:
		indicator.texture = indicator_medium
	else:
		indicator.texture = indicator_burned


func get_meat_quality(meat_type: String) -> String:
	if meat_type == "chicken":
		if chicken_cook_time >= MEAT_BURN_TIME:
			return "burned"
		return "good"

	if beef_cook_time >= MEAT_BURN_TIME:
		return "burned"

	return "good"


func check_knife_cutting() -> void:
	if dragged_object != knife:
		return

	if is_inside_area(knife.global_position, chicken_cut_area):
		spawn_meat_from_knife("chicken")

	if is_inside_area(knife.global_position, beef_cut_area):
		spawn_meat_from_knife("beef")


var last_chicken_cut_time := 0.0
var last_beef_cut_time := 0.0

func spawn_meat_from_knife(meat_type: String) -> void:
	var now := Time.get_ticks_msec() / 1000.0

	if meat_type == "chicken":
		if now - last_chicken_cut_time < 0.6:
			return
		last_chicken_cut_time = now
		create_meat_piece("chicken", chicken_drop_point.global_position)
	else:
		if now - last_beef_cut_time < 0.6:
			return
		last_beef_cut_time = now
		create_meat_piece("beef", beef_drop_point.global_position)


func create_mess(pos: Vector2) -> void:
	cutting_score_data["mess"] += 1

	var mess := Sprite2D.new()
	mess.name = "MeatMess"
	mess.global_position = pos
	mess.texture = mess_texture
	mess.scale = Vector2(0.12, 0.12)

	mess_container.add_child(mess)


func get_next_heated_anchor() -> Marker2D:
	var anchors_parent := heated_area.get_node_or_null("TortillaAnchirs")
	if anchors_parent == null:
		anchors_parent = heated_area.get_node_or_null("TortillaAnchors")

	if anchors_parent == null:
		return null

	for child in anchors_parent.get_children():
		if child is Marker2D:
			var occupied := false

			for tortilla in heated_tortillas:
				if tortilla.global_position.distance_to(child.global_position) < 10:
					occupied = true
					break

			if not occupied:
				return child

	return null


func is_inside_area(point: Vector2, area: Area2D) -> bool:
	var shape_node := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return false

	if shape_node.shape == null:
		return false

	var local_point := shape_node.to_local(point)

	if shape_node.shape is RectangleShape2D:
		var rect := shape_node.shape as RectangleShape2D
		return abs(local_point.x) <= rect.size.x / 2 and abs(local_point.y) <= rect.size.y / 2

	if shape_node.shape is CircleShape2D:
		var circle := shape_node.shape as CircleShape2D
		return local_point.length() <= circle.radius

	return false
