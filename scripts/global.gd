extends Node

# ---------------------------------------------------------
# 1. SIGNALS
# ---------------------------------------------------------
signal day_ended
signal money_changed(new_amount: float)
## Emitted every time the daily cash register changes — for the in-game HUD.
signal daily_earnings_changed(amount: float)

# ---------------------------------------------------------
# 2. ENUMS
# ---------------------------------------------------------

# ---------------------------------------------------------
# 3. CONSTANTS
# ---------------------------------------------------------

# ---------------------------------------------------------
# 4. PUBLIC VARIABLES
# ---------------------------------------------------------
## The player's "pocket". Everything related to player progress lives here.
## Populated from the JSON file when the player selects a Save Slot.
var current_save: Dictionary = {
	"shop_name": "Papa's Shaormeria",
	"day": 1,
	"money": 0.0,
	"upgrades": {},       # e.g. {"faster_grill": true, "extra_sauce": false}
	"customization": {},  # e.g. {"wall_color": "red", "counter_type": "wood"}
	"achievements": {}    # e.g. {"first_sale": true}
}

## Whether the current game period is night (the day timer has run out).
var is_night: bool = false

## The ID of the currently active save slot.
var active_slot_id: int = -1

## The "cash register on the counter" — money earned strictly today.
## Reset to zero at the start of each new day. NOT saved to disk directly;
## it is added to current_save["money"] at end-of-day.
var daily_earnings: float = 0.0

# ---------------------------------------------------------
# 5. PRIVATE VARIABLES
# ---------------------------------------------------------
var _day_timer: Timer

# ---------------------------------------------------------
# 6. ONREADY VARIABLES
# ---------------------------------------------------------

# ---------------------------------------------------------
# 7. GODOT ENGINE FUNCTIONS
# ---------------------------------------------------------
func _ready() -> void:
	_day_timer = Timer.new()
	_day_timer.one_shot = true
	_day_timer.timeout.connect(_on_day_timer_ended)
	add_child(_day_timer)

# ---------------------------------------------------------
# 8. PUBLIC FUNCTIONS
# ---------------------------------------------------------

## Adds money earned from a sale.
## Updates both the global bank account and today's cash register.
func add_money(amount: float) -> void:
	current_save["money"] += amount
	money_changed.emit(current_save["money"])
	daily_earnings += amount
	daily_earnings_changed.emit(daily_earnings)

## Starts the day timer. Called by DayTransition when the player clicks "Start Day".
func start_day(duration_seconds: float) -> void:
	is_night = false
	daily_earnings = 0.0
	daily_earnings_changed.emit(daily_earnings)
	_day_timer.start(duration_seconds)

## Called from the Main Menu when creating or loading a game.
func load_save_data(slot_id: int, parsed_data: Dictionary) -> void:
	active_slot_id = slot_id
	current_save = parsed_data

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
