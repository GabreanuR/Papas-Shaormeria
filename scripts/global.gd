extends Node

# ---------------------------------------------------------
# 1. SIGNALS
# ---------------------------------------------------------
signal day_ended
signal money_changed(new_amount: float)
## Emitted every time the daily cash register changes — for the in-game HUD.
signal daily_earnings_changed(amount: float)
## Emitted when the day counter advances so UI components can update reactively.
signal day_changed(new_day: int)

# ---------------------------------------------------------
# 2. ENUMS
# ---------------------------------------------------------

# ---------------------------------------------------------
# 3. CONSTANTS
# ---------------------------------------------------------
const SAVE_DIR := "user://saves/"
const SAVE_FILE_TEMPLATE := "user://save_slot_%d.json"
const MAX_SAVE_SLOTS := 3
const DEFAULT_STARTING_MONEY := 150.0


# ---------------------------------------------------------
# 4. PUBLIC VARIABLES
# ---------------------------------------------------------
## The player's "pocket". Everything related to player progress lives here.
## Populated from the JSON file when the player selects a Save Slot.
var current_save: Dictionary = {}

## Whether the current game period is night (the day timer has run out).
var is_night: bool = false

## The ID of the currently active save slot.
var active_slot_id: int = -1

## The "cash register on the counter" — money earned strictly today.
## Reset to zero at the start of each new day. NOT saved to disk directly;
## it is added to current_save["money"] at end-of-day.
var daily_earnings: float = 0.0

var daily_stats: Dictionary = {
	"customers_served": 0,
	"perfect_orders": 0,
	"base_income": 0.0,
	"tips_earned": 0.0
}

# ---------------------------------------------------------
# 5. PRIVATE VARIABLES
# ---------------------------------------------------------
var _day_timer: Timer

# ---------------------------------------------------------
# 5b. PUBLIC COMPUTED PROPERTIES
# ---------------------------------------------------------
## Read-only access to the remaining day time. Avoids external scripts
## touching the private _day_timer node directly.
var day_time_left: float:
	get: return _day_timer.time_left if _day_timer else 0.0

# ---------------------------------------------------------
# 6. ONREADY VARIABLES
# ---------------------------------------------------------

# ---------------------------------------------------------
# 7. GODOT ENGINE FUNCTIONS
# ---------------------------------------------------------
func _ready() -> void:
	current_save = get_default_save_data()
	_day_timer = Timer.new()
	_day_timer.one_shot = true
	_day_timer.timeout.connect(_on_day_timer_ended)
	add_child(_day_timer)

# ---------------------------------------------------------
# 8. PUBLIC FUNCTIONS
# ---------------------------------------------------------

## Returns the canonical default save data. Every new save starts from this.
## This is the SINGLE SOURCE OF TRUTH for the save-file schema.
func get_default_save_data(shop_name: String = "Papa's Shaormeria") -> Dictionary:
	return {
		"shop_name": shop_name,
		"day": 1,
		"money": DEFAULT_STARTING_MONEY,
		"reputation": 0,
		"inventory": { "meat_kg": 10.0, "pita_bread": 20, "garlic_sauce": 15, "spicy_sauce": 15 },
		"unlocked_upgrades": [],
		"customization": {},
		"achievements": {}
	}

## Reads a save file and returns the shop_name field, or an error string.
func get_shop_name_from_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return "No Save"

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return "Error Reading"

	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(content) != OK:
		push_error("Save file corrupted or invalid JSON in '%s'. Error on line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return "Corrupt Save"

	var data = json.get_data()
	if typeof(data) == TYPE_DICTIONARY and data.has("shop_name"):
		return str(data["shop_name"])

	return "Unknown Shop"

## Adds money earned from a sale.
## Updates both the global bank account and today's cash register.
func add_money(amount: float) -> void:
	current_save["money"] += amount
	money_changed.emit(current_save["money"])
	daily_earnings += amount
	daily_earnings_changed.emit(daily_earnings)

## Curăță datele zilnice la începutul fiecărei dimineți
func reset_daily_stats() -> void:
	daily_stats = {
		"customers_served": 0,
		"perfect_orders": 0,
		"base_income": 0.0,
		"tips_earned": 0.0
	}
	daily_earnings = 0.0
	daily_earnings_changed.emit(daily_earnings)

## Starts the day timer. Called by DayTransition when the player clicks "Start Day".
func start_day(duration_seconds: float) -> void:
	is_night = false
	reset_daily_stats() # Folosim noua funcție aici!
	_day_timer.start(duration_seconds)

## Advances the day counter by one and resets the night flag.
## Always use this instead of writing to current_save["day"] directly,
## so that all listeners (e.g. TopBar) are notified via day_changed.
func advance_day() -> void:
	current_save["day"] += 1
	is_night = false
	day_changed.emit(current_save["day"])

## Called from the Main Menu when creating or loading a game.
## Merges loaded data on top of defaults so that old saves missing new keys
## still have sensible values (forward-compatible saves).
func load_save_data(slot_id: int, parsed_data: Dictionary) -> void:
	active_slot_id = slot_id
	var defaults := Global.get_default_save_data()
	defaults.merge(parsed_data, true)  # parsed_data wins on conflicts
	current_save = defaults

# ---------------------------------------------------------
# 9. PRIVATE FUNCTIONS
# ---------------------------------------------------------

# ---------------------------------------------------------
# 10. SIGNAL CALLBACKS
# ---------------------------------------------------------
func _on_day_timer_ended() -> void:
	is_night = true
	day_ended.emit()
	# NOTE: Scene navigation is intentionally NOT done here.
	# GameplayMaster listens to `day_ended` and handles the scene transition,
	# keeping Global free of any scene-flow responsibilities.
