extends Node

signal inspection_started
signal inspection_finished
signal timer_updated(time_left: float)
signal penalty_updated(total_penalty: int)
signal cloth_state_changed(is_holding: bool)
signal mess_cleaned_successfully

const CLEAN_LIMIT_SECONDS := 60.0
const PENALTY_INTERVAL_SECONDS := 30.0
const PENALTY_AMOUNT := 100

var dirty_nodes: Array[Node] = []

var inspection_active := false
var time_left := CLEAN_LIMIT_SECONDS
var penalty_timer := 0.0
var total_penalty := 0
var first_penalty_given := false

var holding_cloth := false


func _process(delta: float) -> void:
	if not inspection_active:
		return

	if time_left > 0.0:
		time_left -= delta

		if time_left < 0.0:
			time_left = 0.0

		timer_updated.emit(time_left)

		if time_left <= 0.0 and not first_penalty_given:
			_apply_penalty()
			first_penalty_given = true

		return

	penalty_timer += delta

	if penalty_timer >= PENALTY_INTERVAL_SECONDS:
		penalty_timer = 0.0
		_apply_penalty()


func _input(event: InputEvent) -> void:
	if not holding_cloth:
		return

	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return

		if not event.pressed:
			return

		var clicked_node := _get_dirty_node_under_mouse()

		if clicked_node != null:
			clean_dirty_node(clicked_node)
			get_viewport().set_input_as_handled()


func register_dirty_node(node: Node) -> void:
	if node == null:
		return

	if dirty_nodes.has(node):
		return

	dirty_nodes.append(node)

	if not node.tree_exiting.is_connected(_on_dirty_node_removed.bind(node)):
		node.tree_exiting.connect(_on_dirty_node_removed.bind(node))

	if not inspection_active:
		_start_inspection()


func clean_dirty_node(node: Node) -> void:
	if node == null:
		return

	if dirty_nodes.has(node):
		dirty_nodes.erase(node)

	node.queue_free()

	if dirty_nodes.is_empty():
		_finish_inspection()


func pickup_cloth() -> void:
	holding_cloth = true
	cloth_state_changed.emit(true)


func return_cloth() -> void:
	holding_cloth = false
	cloth_state_changed.emit(false)


func is_holding_cloth() -> bool:
	return holding_cloth


func has_dirty_nodes() -> bool:
	return not dirty_nodes.is_empty()


func _start_inspection() -> void:
	inspection_active = true
	time_left = CLEAN_LIMIT_SECONDS
	penalty_timer = 0.0
	total_penalty = 0
	first_penalty_given = false

	inspection_started.emit()
	timer_updated.emit(time_left)
	penalty_updated.emit(total_penalty)


func _finish_inspection() -> void:
	inspection_active = false
	time_left = CLEAN_LIMIT_SECONDS
	penalty_timer = 0.0
	total_penalty = 0
	first_penalty_given = false

	inspection_finished.emit()
	timer_updated.emit(time_left)
	penalty_updated.emit(total_penalty)
	mess_cleaned_successfully.emit()


func _apply_penalty() -> void:
	total_penalty += PENALTY_AMOUNT

	if Global and Global.has_method("add_money"):
		Global.add_money(-PENALTY_AMOUNT)

	penalty_updated.emit(total_penalty)


func _on_dirty_node_removed(node: Node) -> void:
	if dirty_nodes.has(node):
		dirty_nodes.erase(node)

	if dirty_nodes.is_empty() and inspection_active:
		_finish_inspection()


func _get_dirty_node_under_mouse() -> Node:
	var mouse_pos := get_viewport().get_mouse_position()

	for i in range(dirty_nodes.size() - 1, -1, -1):
		var node := dirty_nodes[i]

		if node == null or not is_instance_valid(node):
			dirty_nodes.remove_at(i)
			continue

		if _is_mouse_over_dirty_node(node, mouse_pos):
			return node

	return null


func _is_mouse_over_dirty_node(node: Node, mouse_pos: Vector2) -> bool:
	if node is Sprite2D:
		return _is_mouse_over_sprite(node as Sprite2D, mouse_pos)

	if node is Area2D:
		var sprite := node.get_node_or_null("Sprite2D") as Sprite2D
		if sprite != null:
			return _is_mouse_over_sprite(sprite, mouse_pos)

		var collision := node.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision != null and collision.shape != null:
			var local_point := collision.get_global_transform_with_canvas().affine_inverse() * mouse_pos

			if collision.shape is CircleShape2D:
				return local_point.length() <= collision.shape.radius + 25.0

			if collision.shape is RectangleShape2D:
				var rect := collision.shape as RectangleShape2D
				return abs(local_point.x) <= rect.size.x / 2.0 + 25.0 and abs(local_point.y) <= rect.size.y / 2.0 + 25.0

	return false


func _is_mouse_over_sprite(sprite: Sprite2D, mouse_pos: Vector2) -> bool:
	var sprite_screen_pos := sprite.get_global_transform_with_canvas().origin
	var distance := sprite_screen_pos.distance_to(mouse_pos)

	if sprite.name == "PataSos":
		return distance <= 55.0

	if sprite.texture == null:
		return distance <= 45.0

	var local_mouse := sprite.get_global_transform_with_canvas().affine_inverse() * mouse_pos
	var texture_size := sprite.texture.get_size()
	var half_size := texture_size / 2.0

	var extra_margin := 25.0

	var inside_texture := local_mouse.x >= -half_size.x - extra_margin \
		and local_mouse.x <= half_size.x + extra_margin \
		and local_mouse.y >= -half_size.y - extra_margin \
		and local_mouse.y <= half_size.y + extra_margin

	if inside_texture:
		return true

	return distance <= 45.0
