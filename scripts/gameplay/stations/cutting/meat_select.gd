extends Node2D

var knife_start_position: Vector2
var knife_swipe_start_y: float = 0.0
var knife_is_swiping: bool = false
var knife_cut_area: String = ""
var knife_min_swipe_distance: float = 80.0
var knife_attached: bool = false

var knife_original_parent: Node

@export var tortilla_texture: Texture2D
@export var meat_chicken_texture: Texture2D
@export var meat_beef_texture: Texture2D

@export var indicator_light: Texture2D
@export var indicator_medium: Texture2D
@export var indicator_burned: Texture2D

@export var chicken_meat_piece_texture: Texture2D
@export var beef_meat_piece_texture: Texture2D

const MEAT_STAGE_1_TIME = 10.0
const MEAT_STAGE_2_TIME = 20.0

@onready var tortilla_template: Area2D = $SpawnedObjects/Tortillas/TortillaTemplate

var knife_has_cut = false

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
	knife_start_position = knife.global_position

	make_draggable(knife)
	knife_start_position = knife.global_position
	chicken_indicator.texture = indicator_light
	beef_indicator.texture = indicator_light
	knife_original_parent = knife.get_parent()
	knife_start_position = knife.global_position


func _process(delta: float) -> void:
	update_dragged_object()
	update_grill(delta)
	update_meat_cooking(delta)
	check_knife_cutting()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return

		if event.pressed:
			if dragged_object == knife:
				var mouse_pos: Vector2 = get_global_mouse_position()
				if not is_inside_area(mouse_pos, chicken_cut_area) and not is_inside_area(mouse_pos, beef_cut_area):
					reset_knife()
			return

		if not event.pressed:
			if dragged_object == null:
				return

			if dragged_object == knife:
				return

			handle_drop(dragged_object)
			dragged_object = null

func _on_tortilla_stack_input(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var tortilla := create_tortilla()
			start_drag(tortilla)


func create_tortilla() -> Area2D:
	var tortilla: Area2D = tortilla_template.duplicate()
	tortilla.visible = true
	tortilla.global_position = tortilla_spawn_point.global_position

	tortilla.set_meta("object_type", "tortilla")
	tortilla.set_meta("heat_state", "raw")
	tortilla.set_meta("has_meat", false)
	tortilla.set_meta("meat_type", "")
	tortilla.set_meta("meat_quality", "")
	tortilla.set_meta("cutting_score", 0)

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
	drag_offset = Vector2.ZERO

	if obj.get_parent() != drag_layer:
		obj.reparent(drag_layer, true)

	obj.global_position = get_global_mouse_position()

func reset_knife() -> void:
	dragged_object = null
	knife_is_swiping = false
	knife_cut_area = ""

	if knife.get_parent() != knife_original_parent:
		knife.reparent(knife_original_parent, true)

	knife.global_position = knife_start_position
	knife.visible = true

func update_dragged_object() -> void:
	if dragged_object == null:
		return

	if dragged_object == knife:
		dragged_object.global_position = get_global_mouse_position()
	else:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			dragged_object.global_position = get_global_mouse_position()


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
	var heat_state: String = tortilla.get_meta("heat_state", "raw")
	var has_meat: bool = tortilla.get_meta("has_meat", false)

	if is_inside_area(tortilla.global_position, trash_zone):
		clear_tortilla_from_grill(tortilla)
		heated_tortillas.erase(tortilla)

		if filling_tortilla == tortilla:
			filling_tortilla = null

		tortilla.queue_free()
		return

	if has_meat:
		if is_inside_area(tortilla.global_position, send_zone):
			send_tortilla_to_assembly(tortilla)
		else:
			return_tortilla_to_valid_place(tortilla)
		return

	if heat_state == "raw" or heat_state == "heating":
		var free_grill_slot: Area2D = get_free_grill_slot_at_position(tortilla.global_position)
		if free_grill_slot != null:
			place_tortilla_on_grill(tortilla, free_grill_slot)
		else:
			tortilla.queue_free()
		return

	if heat_state == "ready":
		if is_inside_area(tortilla.global_position, heated_area):
			place_tortilla_in_heated_area(tortilla)
		elif is_inside_area(tortilla.global_position, filling_area):
			place_tortilla_in_filling_area(tortilla)
		else:
			return_tortilla_to_valid_place(tortilla)

func handle_meat_drop(meat: Area2D) -> void:
	if filling_tortilla != null and is_inside_area(meat.global_position, filling_area):
		add_meat_to_tortilla(meat, filling_tortilla)
	else:
		create_mess_from_meat(meat)
		
		
func return_tortilla_to_valid_place(tortilla: Area2D) -> void:
	for slot in grill_data.keys():
		if grill_data[slot]["tortilla"] == tortilla:
			var anchor: Marker2D = slot.get_node("TortillaAnchor")
			tortilla.global_position = anchor.global_position
			return

	if filling_tortilla == tortilla:
		var anchor: Marker2D = filling_area.get_node("TortillaAnchor")
		tortilla.global_position = anchor.global_position
		return

	if heated_tortillas.has(tortilla):
		var anchor: Marker2D = get_next_heated_anchor()
		if anchor != null:
			tortilla.global_position = anchor.global_position


func create_mess_from_meat(meat: Area2D) -> void:
	cutting_score_data["mess"] += 1

	meat.reparent(mess_container, true)
	meat.set_meta("object_type", "mess")

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

	clear_tortilla_from_grill(tortilla)

	tortilla.reparent(tortillas_container, true)

	var anchor: Marker2D = get_next_heated_anchor()
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

	clear_tortilla_from_grill(tortilla)

	var anchor: Marker2D = filling_area.get_node("TortillaAnchor") as Marker2D

	tortilla.reparent(tortillas_container, true)
	tortilla.global_position = anchor.global_position

	filling_tortilla = tortilla
	heated_tortillas.erase(tortilla)

func clear_tortilla_from_grill(tortilla: Area2D) -> void:
	for slot in grill_data.keys():
		if grill_data[slot]["tortilla"] == tortilla:
			grill_data[slot]["tortilla"] = null
			grill_data[slot]["heat_time"] = 0.0

			var timer_circle: TextureProgressBar = slot.get_node_or_null("HeatTimerCircle")
			if timer_circle != null:
				timer_circle.value = 0

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
		var tortilla = grill_data[slot]["tortilla"]

		if tortilla == null:
			grill_data[slot]["heat_time"] = 0.0
			continue

		if not is_instance_valid(tortilla):
			grill_data[slot]["tortilla"] = null
			grill_data[slot]["heat_time"] = 0.0
			continue

		if tortilla == null or not is_instance_valid(tortilla):
			grill_data[slot]["tortilla"] = null
			grill_data[slot]["heat_time"] = 0.0
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
	var cook_time: float
	var indicator: Sprite2D

	if meat_type == "chicken":
		cook_time = chicken_cook_time
		indicator = chicken_indicator
	else:
		cook_time = beef_cook_time
		indicator = beef_indicator

	if cook_time < MEAT_STAGE_1_TIME:
		indicator.texture = indicator_light
	elif cook_time < MEAT_STAGE_2_TIME:
		indicator.texture = indicator_medium
	else:
		indicator.texture = indicator_burned


func get_meat_quality(meat_type: String) -> String:
	if meat_type == "chicken":
		return "burned" if chicken_cook_time >= MEAT_STAGE_2_TIME else "good"

	return "burned" if beef_cook_time >= MEAT_STAGE_2_TIME else "good"


func check_knife_cutting() -> void:
	if dragged_object != knife:
		return

	var over_chicken: bool = is_inside_area(knife.global_position, chicken_cut_area)
	var over_beef: bool = is_inside_area(knife.global_position, beef_cut_area)

	if not knife_is_swiping:
		if over_chicken:
			knife_is_swiping = true
			knife_swipe_start_y = knife.global_position.y
			knife_cut_area = "chicken"
		elif over_beef:
			knife_is_swiping = true
			knife_swipe_start_y = knife.global_position.y
			knife_cut_area = "beef"
		return

	var swipe_distance: float = knife.global_position.y - knife_swipe_start_y

	if swipe_distance >= knife_min_swipe_distance:
		if knife_cut_area == "chicken" and over_chicken:
			finish_knife_cut("chicken")
		elif knife_cut_area == "beef" and over_beef:
			finish_knife_cut("beef")
			
func finish_knife_cut(meat_type: String) -> void:
	if meat_type == "chicken":
		create_meat_piece("chicken", chicken_drop_point.global_position)
	else:
		create_meat_piece("beef", beef_drop_point.global_position)

	reset_knife()





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
