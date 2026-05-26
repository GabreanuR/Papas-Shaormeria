extends Node2D
@onready var message_label: Label = $MessageLabel
var message_tween: Tween = null

const MAX_HEATED_TORTILLAS := 4

@export var grill_timer_progress_texture: Texture2D
@export var grill_timer_burned_texture: Texture2D



var meat_start_positions := {}
var tortilla_previous_grill_slot := {}
var knife_start_position: Vector2
var knife_swipe_start_y: float = 0.0
var knife_is_swiping: bool = false
var knife_cut_area: String = ""
var knife_min_swipe_distance: float = 80.0
var knife_attached: bool = false

var knife_original_parent: Node
var drag_anchor_local := Vector2.ZERO
@export var chicken_meat_pile: Texture2D
@export var beef_meat_pile: Texture2D


const RAW_TORTILLA_COLOR := Color(1.25, 1.18, 0.85, 1.0)
const READY_TORTILLA_COLOR := Color(1, 1, 1, 1)

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
			var timer_circle := slot.get_node_or_null("HeatTimeCircle") as TextureProgressBar
			if timer_circle != null:
				timer_circle.value = 0
				timer_circle.visible = false
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
	set_tortilla_stack_raw_visual()
	set_tortilla_stack_visual()
	set_tortilla_raw_visual(tortilla_template)
	message_label.visible = false

func set_tortilla_stack_visual() -> void:
	var sprite := tortilla_stack.get_node("Sprite2D") as Sprite2D
	sprite.modulate = Color(0.88, 0.875, 0.86, 1.0)


func set_tortilla_stack_raw_visual() -> void:
	var sprite := tortilla_stack.get_node("Sprite2D") as Sprite2D
	sprite.modulate = Color(0.88, 0.875, 0.86, 1.0)

func show_message(text: String) -> void:
	if message_label == null:
		return

	message_label.text = text
	message_label.visible = true
	message_label.modulate.a = 1.0

	if message_tween != null:
		message_tween.kill()

	message_tween = create_tween()
	message_tween.tween_interval(1.2)
	message_tween.tween_property(message_label, "modulate:a", 0.0, 0.4)
	message_tween.tween_callback(func():
		message_label.visible = false
	)

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
			if knife_attached:
				var knife_pos := knife.to_global(get_drag_anchor_local(knife))

				var over_chicken := is_inside_area(knife_pos, chicken_cut_area)
				var over_beef := is_inside_area(knife_pos, beef_cut_area)

				if over_chicken and get_meat_quality("chicken") != "good":
					show_message("Meat not cooked yet!")
					reset_knife()
					return

				if over_beef and get_meat_quality("beef") != "good":
					show_message("Meat not cooked yet!")
					reset_knife()
					return

				if not over_chicken and not over_beef:
					reset_knife()
					return

			return

		if not event.pressed:
			if dragged_object == null:
				return

			handle_drop(dragged_object)
			dragged_object = null
			
func has_cut_meat_waiting() -> bool:
	for child in meat_pieces_container.get_children():
		if child is Area2D and child.get_meta("object_type", "") == "meat":
			return true

	return false

func _on_tortilla_stack_input(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var tortilla := create_tortilla()
			start_drag(tortilla)


func create_tortilla() -> Area2D:
	var tortilla: Area2D = tortilla_template.duplicate()
	tortilla.visible = true
	var sprite := tortilla.get_node("Sprite2D") as Sprite2D
	sprite.modulate = RAW_TORTILLA_COLOR
	normalize_area2d_origin(tortilla)
	

	tortilla.global_position = tortilla_spawn_point.global_position

	tortilla.set_meta("object_type", "tortilla")
	tortilla.set_meta("heat_state", "raw")
	tortilla.set_meta("has_meat", false)
	tortilla.set_meta("meat_type", "")
	tortilla.set_meta("meat_quality", "")
	tortilla.set_meta("cutting_score", 0)
	set_tortilla_raw_visual(tortilla)

	tortillas_container.add_child(tortilla)
	make_draggable(tortilla)

	return tortilla


func normalize_area2d_origin(obj: Area2D) -> void:
	var anchor := get_drag_anchor_local(obj)
	if anchor == Vector2.ZERO:
		return

	for child in obj.get_children():
		if child is Node2D:
			child.position -= anchor

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

	sprite.scale = Vector2(0.3, 0.3)
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
			if obj == knife:
				attach_knife_to_mouse()
			else:
				start_drag(obj)

func attach_knife_to_mouse() -> void:
	dragged_object = null
	knife_attached = true
	knife_is_swiping = false
	knife_cut_area = ""

	drag_anchor_local = get_drag_anchor_local(knife)

	if knife.get_parent() != drag_layer:
		knife.reparent(drag_layer, true)

	knife.z_index = 1000
	move_node_anchor_to_mouse(knife, drag_anchor_local)


func start_drag(obj: Area2D) -> void:
	if heated_tortillas.has(obj):
		var top_tortilla: Area2D = heated_tortillas[heated_tortillas.size() - 1]

		if obj != top_tortilla:
			return

		heated_tortillas.erase(obj)
		obj.input_pickable = true

		var collision := obj.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision != null:
			collision.disabled = false

		refresh_heated_tortilla_stack_interaction()

	if obj.get_meta("object_type", "") == "meat":
		meat_start_positions[obj] = obj.global_position

	if obj.get_meta("object_type", "") == "tortilla":
		for slot in grill_data.keys():
			if grill_data[slot]["tortilla"] == obj:
				tortilla_previous_grill_slot[obj] = slot
				obj.set_meta("saved_heat_time", grill_data[slot]["heat_time"])
				grill_data[slot]["tortilla"] = null
				break

	dragged_object = obj
	drag_anchor_local = get_drag_anchor_local(obj)

	if obj.get_parent() != drag_layer:
		obj.reparent(drag_layer, true)

	move_dragged_to_mouse()
	obj.z_index = 1000

func reset_knife() -> void:
	dragged_object = null
	knife_attached = false
	knife_is_swiping = false
	knife_cut_area = ""

	if knife.get_parent() != knife_original_parent:
		knife.reparent(knife_original_parent, true)

	knife.global_position = knife_start_position
	knife.z_index = 20
	knife.visible = true
	knife.input_pickable = true

	var collision := knife.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision != null:
		collision.disabled = false
		

func update_dragged_object() -> void:
	if knife_attached:
		move_node_anchor_to_mouse(knife, drag_anchor_local)
		return

	if dragged_object == null:
		return

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		move_dragged_to_mouse()
		

func move_node_anchor_to_mouse(obj: Node2D, anchor_local: Vector2) -> void:
	var mouse_pos := get_global_mouse_position()
	var anchor_global := obj.to_global(anchor_local)
	var offset := anchor_global - obj.global_position
	obj.global_position = mouse_pos - offset

func get_drag_anchor_local(obj: Area2D) -> Vector2:
	var collision := obj.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision != null:
		return collision.position

	var sprite := obj.get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		return sprite.position

	return Vector2.ZERO
	
func move_dragged_to_mouse() -> void:
	move_node_anchor_to_mouse(dragged_object, drag_anchor_local)


func reset_draggable(obj: Area2D) -> void:
	if obj.get_parent() != tortillas_container:
		obj.reparent(tortillas_container, true)

	obj.z_index = 0

func place_object_anchor_at(obj: Area2D, target_global_pos: Vector2) -> void:
	var anchor_local := get_drag_anchor_local(obj)
	var anchor_global := obj.to_global(anchor_local)
	var offset := anchor_global - obj.global_position
	obj.global_position = target_global_pos - offset

func handle_drop(obj: Area2D) -> void:
	var object_type: String = obj.get_meta("object_type", "")
	var drop_pos := obj.to_global(get_drag_anchor_local(obj))

	if is_inside_area(drop_pos, trash_zone):
		obj.queue_free()
		return

	if object_type == "tortilla":
		handle_tortilla_drop(obj)
	elif object_type == "meat":
		handle_meat_drop(obj)

func handle_tortilla_drop(tortilla: Area2D) -> void:
	var heat_state: String = tortilla.get_meta("heat_state", "raw")
	var has_meat: bool = tortilla.get_meta("has_meat", false)
	var drop_pos := tortilla.to_global(get_drag_anchor_local(tortilla))

	if not has_meat and is_inside_area(drop_pos, send_zone):
		show_message("You can't send a tortilla without meat!")
		return_tortilla_to_valid_place(tortilla)
		return

	if has_meat:
		if is_inside_area(drop_pos, send_zone):
			send_tortilla_to_assembly(tortilla)
		else:
			return_tortilla_to_valid_place(tortilla)
		return

	if heat_state == "raw" or heat_state == "heating":
		var free_slot := get_free_grill_slot_at_position(drop_pos)

		if free_slot != null:
			place_tortilla_on_grill(tortilla, free_slot)
		else:
			if is_inside_area(drop_pos, heated_area) or is_inside_area(drop_pos, filling_area):
				show_message("Not heated yet!")

			return_tortilla_to_previous_grill_slot(tortilla)

		return

	if heat_state == "ready" or heat_state == "burned":
		if is_inside_area(drop_pos, filling_area):
			if filling_tortilla == null:
				place_tortilla_in_filling_area(tortilla)
			else:
				return_tortilla_to_valid_place(tortilla)
			return

		if is_inside_area(drop_pos, heated_area):
			if heated_tortillas.size() < MAX_HEATED_TORTILLAS:
				place_tortilla_in_heated_area(tortilla)
			else:
				return_tortilla_to_valid_place(tortilla)
			return

		return_tortilla_to_valid_place(tortilla)
		
func return_tortilla_to_previous_grill_slot(tortilla: Area2D) -> void:
	if tortilla_previous_grill_slot.has(tortilla):
		var slot: Area2D = tortilla_previous_grill_slot[tortilla]

		if is_instance_valid(slot):
			place_tortilla_on_existing_grill_slot(tortilla, slot)
			return

	tortilla.queue_free()
	
func place_tortilla_on_existing_grill_slot(tortilla: Area2D, slot: Area2D) -> void:
	var anchor := slot.get_node_or_null("TortillaAnchor") as Marker2D

	tortilla.reparent(tortillas_container, true)

	if anchor != null:
		tortilla.global_position = anchor.global_position
	else:
		tortilla.global_position = get_area_center_global(slot)

	tortilla.z_index = 20
	grill_data[slot]["tortilla"] = tortilla

	if tortilla.get_meta("heat_state", "raw") == "raw":
		tortilla.set_meta("heat_state", "heating")

	tortilla_previous_grill_slot[tortilla] = slot

	if tortilla.get_meta("heat_state", "") == "burned":
		var sprite := tortilla.get_node("Sprite2D") as Sprite2D
		sprite.modulate = Color(0.45, 0.25, 0.12, 1.0)
	elif tortilla.get_meta("heat_state", "") == "ready":
		set_tortilla_ready_visual(tortilla)
	else:
		set_tortilla_raw_visual(tortilla)

		
func try_return_ready_tortilla(tortilla: Area2D) -> void:
	if heated_tortillas.size() < MAX_HEATED_TORTILLAS:
		place_tortilla_in_heated_area(tortilla)
		return

	var free_slot := get_any_free_grill_slot()
	if free_slot != null:
		place_tortilla_on_grill(tortilla, free_slot)
	else:
		return_tortilla_to_valid_place(tortilla)
func get_any_free_grill_slot() -> Area2D:
	for slot in grill_data.keys():
		if grill_data[slot]["tortilla"] == null:
			return slot
	return null

func get_area_center_global(area: Area2D) -> Vector2:
	var collision := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		return area.global_position

	return collision.global_position

func handle_meat_drop(meat: Area2D) -> void:
	var meat_pos := meat.to_global(get_drag_anchor_local(meat))

	if filling_tortilla != null and is_inside_area(meat_pos, filling_area):
		if filling_tortilla.get_meta("has_meat", false):
			show_message("You can't add more meat!")
			return_meat_to_start(meat)
			return

		add_meat_to_tortilla(meat, filling_tortilla)
		return

	if filling_tortilla == null and is_inside_area(meat_pos, filling_area):
		show_message("You need a tortilla to place the meat!")
		return_meat_to_start(meat)
		return

	if is_inside_area(meat_pos, tortilla_stack):
		return_meat_to_start(meat)
		return

	if is_inside_area(meat_pos, heated_area):
		return_meat_to_start(meat)
		return

	for slot in grill_data.keys():
		if is_inside_area(meat_pos, slot):
			return_meat_to_start(meat)
			return

	create_mess_from_meat(meat)
		
func return_meat_to_start(meat: Area2D) -> void:
	if meat.get_parent() != meat_pieces_container:
		meat.reparent(meat_pieces_container, true)

	if meat_start_positions.has(meat):
		meat.global_position = meat_start_positions[meat]

	meat.z_index = 20
		
		
func create_meat_mess_at(global_pos: Vector2) -> void:
	cutting_score_data["mess"] += 1

	var mess := Sprite2D.new()
	mess.name = "MeatMess"

	mess.texture = meat_chicken_texture
	mess.scale = Vector2(0.08, 0.08)
	mess.global_position = global_pos
	mess.z_index = 30

	mess_container.add_child(mess)
		
func return_tortilla_to_valid_place(tortilla: Area2D) -> void:
	var heat_state: String = tortilla.get_meta("heat_state", "raw")

	if filling_tortilla == tortilla:
		var anchor: Marker2D = filling_area.get_node("TortillaAnchor")
		tortilla.reparent(tortillas_container, true)
		tortilla.global_position = anchor.global_position
		tortilla.z_index = 30
		return

	if heated_tortillas.has(tortilla):
		var anchor := get_current_heated_anchor_for(tortilla)
		if anchor != null:
			tortilla.reparent(tortillas_container, true)
			tortilla.global_position = anchor.global_position
			tortilla.z_index = 20 + heated_tortillas.find(tortilla)
			return

	if heat_state == "ready" or heat_state == "burned":
		if heated_tortillas.size() < MAX_HEATED_TORTILLAS:
			place_tortilla_in_heated_area(tortilla)
		elif filling_tortilla == null:
			place_tortilla_in_filling_area(tortilla)
		else:
			tortilla.queue_free()
		return

	return_tortilla_to_previous_grill_slot(tortilla)
	
func get_current_heated_anchor_for(tortilla: Area2D) -> Marker2D:
	var anchors_parent := heated_area.get_node_or_null("TortillaAnchirs")
	if anchors_parent == null:
		anchors_parent = heated_area.get_node_or_null("TortillaAnchors")

	if anchors_parent == null:
		return null

	var index := heated_tortillas.find(tortilla)
	if index < 0:
		return null

	var anchors: Array[Marker2D] = []
	for child in anchors_parent.get_children():
		if child is Marker2D:
			anchors.append(child)

	if index >= anchors.size():
		return null

	return anchors[index]

func create_mess_from_meat(meat: Area2D) -> void:
	cutting_score_data["mess"] += 1

	if meat.get_parent() != mess_container:
		meat.reparent(mess_container, true)

	meat.set_meta("object_type", "mess")

	var sprite := meat.get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		sprite.modulate = Color(0.55, 0.45, 0.38, 1.0)

	meat.z_index = 10
	meat.input_pickable = false

	var collision := meat.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision != null:
		collision.disabled = true

func get_free_grill_slot_at_position(pos: Vector2) -> Area2D:
	for slot in grill_data.keys():
		if is_inside_area(pos, slot) and grill_data[slot]["tortilla"] == null:
			return slot

	return null

func place_tortilla_on_grill(tortilla: Area2D, slot: Area2D) -> void:
	clear_tortilla_from_grill(tortilla, true)

	var anchor := slot.get_node_or_null("TortillaAnchor") as Marker2D

	tortilla.reparent(tortillas_container, true)

	if anchor != null:
		tortilla.global_position = anchor.global_position
	else:
		tortilla.global_position = get_area_center_global(slot)

	tortilla.z_index = 20

	grill_data[slot]["tortilla"] = tortilla
	if tortilla_previous_grill_slot.has(tortilla):
		grill_data[slot]["heat_time"] = tortilla.get_meta("saved_heat_time", 0.0)
	else:
		grill_data[slot]["heat_time"] = 0.0

	var timer_circle := slot.get_node_or_null("HeatTimeCircle") as TextureProgressBar

	if timer_circle != null:
		timer_circle.visible = true
		timer_circle.show()
		timer_circle.top_level = false
		timer_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE

		timer_circle.min_value = 0
		timer_circle.max_value = 100
		timer_circle.value = 0

		timer_circle.move_to_front()

	tortilla_previous_grill_slot[tortilla] = slot

	tortilla.set_meta("heat_state", "heating")
	remove_glow(tortilla)
	set_tortilla_raw_visual(tortilla)
	

func set_tortilla_raw_visual(tortilla: Area2D) -> void:
	var sprite := tortilla.get_node("Sprite2D") as Sprite2D
	sprite.modulate = Color(0.88, 0.875, 0.86, 1.0)


func set_tortilla_ready_visual(tortilla: Area2D) -> void:
	var sprite := tortilla.get_node("Sprite2D") as Sprite2D
	sprite.modulate = Color(1, 1, 1, 1)


func place_tortilla_in_heated_area(tortilla: Area2D) -> void:
	var heat_state: String = tortilla.get_meta("heat_state", "raw")

	if heat_state != "ready" and heat_state != "burned":
		return

	clear_tortilla_from_grill(tortilla)

	tortilla.reparent(tortillas_container, true)

	var anchor: Marker2D = get_next_heated_anchor()

	if anchor != null:
		tortilla.global_position = anchor.global_position

	if heated_tortillas.has(tortilla):
		heated_tortillas.erase(tortilla)

	heated_tortillas.append(tortilla)

	for i in range(heated_tortillas.size()):
		var t := heated_tortillas[i]
		t.z_index = 20 + i

	refresh_heated_tortilla_stack_interaction()


func place_tortilla_in_filling_area(tortilla: Area2D) -> void:
	if filling_tortilla != null:
		return

	var heat_state: String = tortilla.get_meta("heat_state", "raw")

	if heat_state != "ready" and heat_state != "burned":
		return

	clear_tortilla_from_grill(tortilla, true)

	var anchor: Marker2D = filling_area.get_node("TortillaAnchor") as Marker2D

	tortilla.reparent(tortillas_container, true)
	tortilla.global_position = anchor.global_position
	tortilla.z_index = 30

	filling_tortilla = tortilla

	heated_tortillas.erase(tortilla)

	refresh_heated_tortilla_stack_interaction()

func clear_tortilla_from_grill(tortilla: Area2D, reset_timer := true) -> void:
	for slot in grill_data.keys():
		if grill_data[slot]["tortilla"] == tortilla:
			grill_data[slot]["tortilla"] = null

			if reset_timer:
				grill_data[slot]["heat_time"] = 0.0

				var timer_circle := slot.get_node_or_null("HeatTimeCircle") as TextureProgressBar

				if timer_circle != null:
					timer_circle.value = 0
					timer_circle.visible = true

func has_cut_meat_waiting_of_type(meat_type: String) -> bool:
	for child in meat_pieces_container.get_children():
		if child is Area2D:
			if child.get_meta("object_type", "") == "meat" and child.get_meta("meat_type", "") == meat_type:
				return true

	return false

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
		if chicken_meat_pile:
			meat_sprite.texture = chicken_meat_pile
		else:
			meat_sprite.texture = meat_chicken_texture
	else:
		if beef_meat_pile:
			meat_sprite.texture = beef_meat_pile
		else:
			meat_sprite.texture = meat_beef_texture

	meat_sprite.scale = Vector2(0.08, 0.08)
	meat_sprite.z_index = 100

	var meat_container := tortilla.get_node("MeatContainer") as Node2D
	meat_container.add_child(meat_sprite)

	# pozitie noua
	meat_sprite.position = Vector2(-160, -78)

	if meat_quality == "burned":
		cutting_score_data["burned_meat"] += 1
	else:
		cutting_score_data["good_meat"] += 1

	meat.queue_free()
	
func refresh_heated_tortilla_stack_interaction() -> void:
	for i in range(heated_tortillas.size()):
		var tortilla: Area2D = heated_tortillas[i]

		if not is_instance_valid(tortilla):
			continue

		var is_top := i == heated_tortillas.size() - 1

		tortilla.input_pickable = is_top

		var collision := tortilla.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision != null:
			collision.disabled = not is_top


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

	refresh_heated_tortilla_stack_interaction()

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
		var timer_circle := slot.get_node_or_null("HeatTimeCircle") as TextureProgressBar

		if tortilla == null:
			if timer_circle != null:
				timer_circle.visible = true
				timer_circle.show()
				timer_circle.top_level = false
				timer_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
				timer_circle.value = 0

				if grill_timer_progress_texture != null:
					timer_circle.texture_progress = grill_timer_progress_texture

				timer_circle.move_to_front()
			continue

		if tortilla == dragged_object:
			continue

		if not is_instance_valid(tortilla):
			grill_data[slot]["tortilla"] = null
			grill_data[slot]["heat_time"] = 0.0

			if timer_circle != null:
				timer_circle.visible = true
				timer_circle.value = 0
			continue

		grill_data[slot]["heat_time"] += delta
		var heat_time: float = grill_data[slot]["heat_time"]

		if timer_circle != null:
			timer_circle.visible = true
			timer_circle.show()
			timer_circle.top_level = false
			timer_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE

			timer_circle.value = clamp(
				(heat_time / TORTILLA_HEAT_TIME) * 100.0,
				0.0,
				100.0
			)

			if heat_time >= TORTILLA_BURN_TIME:
				timer_circle.value = 100
				if grill_timer_burned_texture != null:
					timer_circle.texture_progress = grill_timer_burned_texture
			else:
				if grill_timer_progress_texture != null:
					timer_circle.texture_progress = grill_timer_progress_texture

			timer_circle.move_to_front()

		if heat_time >= TORTILLA_HEAT_TIME and tortilla.get_meta("heat_state", "") == "heating":
			tortilla.set_meta("heat_state", "ready")
			set_tortilla_ready_visual(tortilla)

		if heat_time >= TORTILLA_BURN_TIME and tortilla.get_meta("heat_state", "") != "burned":
			tortilla.set_meta("heat_state", "burned")
			cutting_score_data["burned_tortillas"] += 1
			remove_glow(tortilla)

			var sprite := tortilla.get_node("Sprite2D") as Sprite2D
			sprite.modulate = Color(0.45, 0.25, 0.12, 1.0)
			
func add_glow(tortilla: Area2D) -> void:
	var sprite := tortilla.get_node("Sprite2D") as Sprite2D
	sprite.modulate = READY_TORTILLA_COLOR


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
	var cook_time := chicken_cook_time if meat_type == "chicken" else beef_cook_time

	if cook_time < MEAT_STAGE_2_TIME:
		return "raw"

	return "good"

func check_knife_cutting() -> void:
	if not knife_attached:
		return

	var knife_pos := knife.to_global(get_drag_anchor_local(knife))

	var over_chicken := is_inside_area(knife_pos, chicken_cut_area)
	var over_beef := is_inside_area(knife_pos, beef_cut_area)

	if not over_chicken and not over_beef:
		knife_is_swiping = false
		knife_cut_area = ""
		return

	if not knife_is_swiping:
		if over_chicken:
			knife_is_swiping = true
			knife_swipe_start_y = knife_pos.y
			knife_cut_area = "chicken"
		elif over_beef:
			knife_is_swiping = true
			knife_swipe_start_y = knife_pos.y
			knife_cut_area = "beef"
		return

	var swipe_distance := knife_pos.y - knife_swipe_start_y

	if swipe_distance >= knife_min_swipe_distance:
		if knife_cut_area == "chicken" and over_chicken:
			finish_knife_cut("chicken")
		elif knife_cut_area == "beef" and over_beef:
			finish_knife_cut("beef")
			
			
func finish_knife_cut(meat_type: String) -> void:
	if has_cut_meat_waiting_of_type(meat_type):
		show_message("You have to use the meat below first!")
		reset_knife()
		return

	if get_meat_quality(meat_type) != "good":
		show_message("Meat not cooked yet!")
		reset_knife()
		return

	if meat_type == "chicken":
		create_meat_piece("chicken", chicken_drop_point.global_position)
		chicken_cook_time = 0.0
		chicken_indicator.texture = indicator_light
	else:
		create_meat_piece("beef", beef_drop_point.global_position)
		beef_cook_time = 0.0
		beef_indicator.texture = indicator_light

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
