extends GutTest

# =============================================================
# test_global.gd — Unit tests for res://scripts/global.gd
# =============================================================

const GlobalScript = preload("res://scripts/global.gd")
var global_node: GlobalScript

func before_each() -> void:
	# Create a fresh instance of Global for every test so they don't interfere.
	global_node = GlobalScript.new()
	add_child_autofree(global_node)
	# Wait one frame so _ready() finishes (timer created, etc.)
	await get_tree().process_frame


# ---------------------------------------------------------
# get_default_save_data()
# ---------------------------------------------------------
func test_default_save_returns_dictionary() -> void:
	var data = global_node.get_default_save_data()
	assert_typeof(data, TYPE_DICTIONARY, "get_default_save_data() should return a Dictionary")

func test_default_save_has_required_keys() -> void:
	var data = global_node.get_default_save_data()
	var expected_keys := ["shop_name", "day", "money", "reputation",
						  "inventory", "unlocked_upgrades",
						  "customization", "achievements"]
	for key in expected_keys:
		assert_has(data, key, "Default save must contain key '%s'" % key)

func test_default_save_starting_money() -> void:
	var data = global_node.get_default_save_data()
	assert_eq(data["money"], 150.0, "Starting money should be 150.0")

func test_default_save_starts_on_day_one() -> void:
	var data = global_node.get_default_save_data()
	assert_eq(data["day"], 1, "Starting day should be 1")

func test_default_save_custom_shop_name() -> void:
	var data = global_node.get_default_save_data("La Ionuț")
	assert_eq(data["shop_name"], "La Ionuț", "Custom shop name should be preserved")

func test_default_save_inventory_is_non_empty() -> void:
	var data = global_node.get_default_save_data()
	assert_gt(data["inventory"].size(), 0, "Default inventory should have items")


# ---------------------------------------------------------
# add_money()
# ---------------------------------------------------------
func test_add_money_increases_balance() -> void:
	global_node.current_save = global_node.get_default_save_data()
	var initial_money: float = global_node.current_save["money"]
	global_node.add_money(25.0)
	assert_eq(global_node.current_save["money"], initial_money + 25.0)

func test_add_money_increases_daily_earnings() -> void:
	global_node.current_save = global_node.get_default_save_data()
	global_node.daily_earnings = 0.0
	global_node.add_money(10.0)
	global_node.add_money(5.0)
	assert_eq(global_node.daily_earnings, 15.0,
			  "daily_earnings should accumulate all add_money calls")

func test_add_money_emits_money_changed_signal() -> void:
	global_node.current_save = global_node.get_default_save_data()
	watch_signals(global_node)
	global_node.add_money(42.0)
	assert_signal_emitted(global_node, "money_changed")

func test_add_money_emits_daily_earnings_changed_signal() -> void:
	global_node.current_save = global_node.get_default_save_data()
	watch_signals(global_node)
	global_node.add_money(7.5)
	assert_signal_emitted(global_node, "daily_earnings_changed")

func test_add_money_negative_amount() -> void:
	global_node.current_save = global_node.get_default_save_data()
	var initial_money: float = global_node.current_save["money"]
	global_node.add_money(-30.0)
	assert_eq(global_node.current_save["money"], initial_money - 30.0,
			  "Negative amounts should decrease the balance (e.g. purchase)")


# ---------------------------------------------------------
# reset_daily_stats()
# ---------------------------------------------------------
func test_reset_daily_stats_zeros_earnings() -> void:
	global_node.daily_earnings = 999.0
	global_node.reset_daily_stats()
	assert_eq(global_node.daily_earnings, 0.0)

func test_reset_daily_stats_zeros_customers_served() -> void:
	global_node.daily_stats["customers_served"] = 12
	global_node.reset_daily_stats()
	assert_eq(global_node.daily_stats["customers_served"], 0)

func test_reset_daily_stats_zeros_perfect_orders() -> void:
	global_node.daily_stats["perfect_orders"] = 5
	global_node.reset_daily_stats()
	assert_eq(global_node.daily_stats["perfect_orders"], 0)

func test_reset_daily_stats_emits_daily_earnings_changed() -> void:
	watch_signals(global_node)
	global_node.reset_daily_stats()
	assert_signal_emitted(global_node, "daily_earnings_changed")


# ---------------------------------------------------------
# load_save_data()
# ---------------------------------------------------------
func test_load_save_data_sets_active_slot() -> void:
	global_node.load_save_data(2, {"shop_name": "Test"})
	assert_eq(global_node.active_slot_id, 2)

func test_load_save_data_merges_with_defaults() -> void:
	# Simulate an old save that is missing "achievements"
	var old_save := {"shop_name": "Old Shop", "day": 5, "money": 300.0}
	global_node.load_save_data(1, old_save)
	assert_has(global_node.current_save, "achievements",
			   "Missing keys should be filled from defaults")
	assert_eq(global_node.current_save["shop_name"], "Old Shop",
			  "Loaded data should override defaults")
	assert_eq(global_node.current_save["day"], 5)

func test_load_save_data_preserves_loaded_money() -> void:
	global_node.load_save_data(1, {"money": 999.99})
	assert_eq(global_node.current_save["money"], 999.99,
			  "Loaded money should win over the default")


# ---------------------------------------------------------
# start_day()
# ---------------------------------------------------------
func test_start_day_clears_night_flag() -> void:
	global_node.is_night = true
	global_node.current_save = global_node.get_default_save_data()
	global_node.start_day(60.0)
	assert_false(global_node.is_night, "is_night should be false after starting a day")

func test_start_day_resets_daily_stats() -> void:
	global_node.daily_earnings = 100.0
	global_node.daily_stats["customers_served"] = 5
	global_node.current_save = global_node.get_default_save_data()
	global_node.start_day(60.0)
	assert_eq(global_node.daily_earnings, 0.0)
	assert_eq(global_node.daily_stats["customers_served"], 0)


# ---------------------------------------------------------
# advance_day()
# ---------------------------------------------------------
func test_advance_day_increments_day_counter() -> void:
	global_node.current_save = global_node.get_default_save_data()
	global_node.active_slot_id = 1
	global_node.advance_day()
	assert_eq(global_node.current_save["day"], 2)

func test_advance_day_clears_night_flag() -> void:
	global_node.current_save = global_node.get_default_save_data()
	global_node.active_slot_id = 1
	global_node.is_night = true
	global_node.advance_day()
	assert_false(global_node.is_night)

func test_advance_day_emits_day_changed() -> void:
	global_node.current_save = global_node.get_default_save_data()
	global_node.active_slot_id = 1
	watch_signals(global_node)
	global_node.advance_day()
	assert_signal_emitted(global_node, "day_changed")


# ---------------------------------------------------------
# end_day_and_save_earnings()
# ---------------------------------------------------------
func test_end_day_adds_earnings_to_money() -> void:
	global_node.current_save = global_node.get_default_save_data()
	global_node.active_slot_id = 1
	global_node.daily_earnings = 50.0
	var expected: float = float(global_node.current_save["money"]) + 50.0
	global_node.end_day_and_save_earnings()
	assert_eq(global_node.current_save["money"], expected)

func test_end_day_resets_daily_earnings() -> void:
	global_node.current_save = global_node.get_default_save_data()
	global_node.active_slot_id = 1
	global_node.daily_earnings = 75.0
	global_node.end_day_and_save_earnings()
	assert_eq(global_node.daily_earnings, 0.0)


# ---------------------------------------------------------
# Constants sanity checks
# ---------------------------------------------------------
func test_max_save_slots_is_positive() -> void:
	assert_gt(global_node.MAX_SAVE_SLOTS, 0)

func test_default_starting_money_is_positive() -> void:
	assert_gt(global_node.DEFAULT_STARTING_MONEY, 0.0)
