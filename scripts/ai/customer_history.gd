extends Node

const MAX_HISTORY := 3
const WRONG_ORDER_LIMIT := 70

static var active_slot_id: int = 1

static func set_active_slot(slot_id: int) -> void:
	active_slot_id = max(1, slot_id)

static func _history_path() -> String:
	return "user://loyal_customer_history_slot_%d.json" % active_slot_id

static func reset_history_for_slot(slot_id: int) -> void:
	var path := "user://loyal_customer_history_slot_%d.json" % max(1, slot_id)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

static func load_history() -> Array:
	var path := _history_path()

	print("PAPA LOAD HISTORY FROM: ", path)

	if not FileAccess.file_exists(path):
		print("PAPA FILE DOES NOT EXIST")
		return []

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("PAPA FILE FAILED TO OPEN")
		return []

	var content := file.get_as_text()
	file.close()

	print("PAPA FILE CONTENT: ", content)

	var json := JSON.new()
	if json.parse(content) != OK:
		print("PAPA JSON ERROR")
		return []

	var data = json.get_data()
	return data if typeof(data) == TYPE_ARRAY else []
	
static func save_interaction(entry: Dictionary) -> void:
	print("PAPA SAVE ENTRY: ", entry)
	print("PAPA SAVE PATH: ", _history_path())

	var history := load_history()
	history.append(entry)

	while history.size() > MAX_HISTORY:
		history.pop_front()

	var file := FileAccess.open(_history_path(), FileAccess.WRITE)
	if file == null:
		print("PAPA SAVE FAILED")
		return

	file.store_string(JSON.stringify(history))
	file.close()

	print("PAPA SAVE SUCCESS")
	
static func last_order_was_wrong() -> bool:
	var history := load_history()
	if history.is_empty():
		return false

	var last_entry: Dictionary = history.back()
	return int(last_entry.get("score", 100)) < WRONG_ORDER_LIMIT

static func has_any_history() -> bool:
	return not load_history().is_empty()
