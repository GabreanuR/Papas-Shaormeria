extends Node

const HISTORY_PATH := "user://loyal_customer_history.json"
const MAX_HISTORY := 3
const WRONG_ORDER_LIMIT := 70


static func load_history() -> Array:
	if not FileAccess.file_exists(HISTORY_PATH):
		return []

	var file := FileAccess.open(HISTORY_PATH, FileAccess.READ)
	if file == null:
		return []

	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(content)

	if err != OK:
		return []

	var data = json.get_data()
	if typeof(data) != TYPE_ARRAY:
		return []

	return data


static func save_interaction(entry: Dictionary) -> void:
	var history := load_history()
	history.append(entry)

	while history.size() > MAX_HISTORY:
		history.pop_front()

	var file := FileAccess.open(HISTORY_PATH, FileAccess.WRITE)
	if file == null:
		return

	file.store_string(JSON.stringify(history))
	file.close()


static func last_order_was_wrong() -> bool:
	var history := load_history()

	if history.is_empty():
		return false

	var last_entry: Dictionary = history.back()
	return int(last_entry.get("score", 100)) < WRONG_ORDER_LIMIT
