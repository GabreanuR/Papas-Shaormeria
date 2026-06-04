extends GutTest

# =============================================================
# test_gameplay_master.gd — Unit tests for the static / pure
# logic inside gameplay_master.gd (pita state, scoring, tips).
#
# IMPORTANT: We do NOT add_child() the GameplayMaster node
# because its _ready() depends on the full scene tree
# (%OrderStation, %MeatSelect, etc.). Instead, we call methods
# directly on un-parented instances or use static helpers.
# =============================================================

const GameplayMasterScript = preload("res://scripts/gameplay/master/gameplay_master.gd")


# ---------------------------------------------------------
# _new_pita_state()  (static)
# ---------------------------------------------------------
func test_new_pita_state_returns_dictionary() -> void:
	var state = GameplayMasterScript._new_pita_state()
	assert_typeof(state, TYPE_DICTIONARY)

func test_new_pita_state_has_required_keys() -> void:
	var state = GameplayMasterScript._new_pita_state()
	var keys := ["lipie_quality", "meat_type", "is_cut",
				 "sauces", "vegetables", "scores", "total_score"]
	for key in keys:
		assert_has(state, key, "Pita state must contain '%s'" % key)

func test_new_pita_state_default_values() -> void:
	var state = GameplayMasterScript._new_pita_state()
	assert_eq(state["lipie_quality"], "ready")
	assert_eq(state["meat_type"], "")
	assert_false(state["is_cut"])
	assert_eq(state["sauces"].size(), 0)
	assert_eq(state["vegetables"].size(), 0)
	assert_eq(state["total_score"], 0)

func test_new_pita_state_scores_all_zero() -> void:
	var state = GameplayMasterScript._new_pita_state()
	for station_name in state["scores"]:
		assert_eq(state["scores"][station_name], 0,
				  "Score for '%s' should start at 0" % station_name)

func test_new_pita_state_has_four_score_categories() -> void:
	var state = GameplayMasterScript._new_pita_state()
	var expected_stations := ["cutting", "waiting", "assembly", "wrapping"]
	for station in expected_stations:
		assert_has(state["scores"], station,
				   "Scores should include '%s'" % station)


# ---------------------------------------------------------
# update_station_score()
# We create the node but do NOT add it to the tree, so
# _ready() never fires and @onready vars stay null.
# update_station_score() only touches current_pita_state
# (a plain Dictionary), so it works fine without the tree.
# ---------------------------------------------------------
func test_update_station_score_sets_value() -> void:
	var gm = GameplayMasterScript.new()
	gm.current_pita_state = GameplayMasterScript._new_pita_state()
	gm.update_station_score("cutting", 25)
	assert_eq(gm.current_pita_state["scores"]["cutting"], 25)
	gm.free()

func test_update_station_score_recalculates_total() -> void:
	var gm = GameplayMasterScript.new()
	gm.current_pita_state = GameplayMasterScript._new_pita_state()
	gm.update_station_score("cutting", 25)
	gm.update_station_score("waiting", 25)
	gm.update_station_score("assembly", 25)
	gm.update_station_score("wrapping", 25)
	assert_eq(gm.current_pita_state["total_score"], 100,
			  "Total score should be the sum of all stations")
	gm.free()

func test_update_station_score_overwrites_previous() -> void:
	var gm = GameplayMasterScript.new()
	gm.current_pita_state = GameplayMasterScript._new_pita_state()
	gm.update_station_score("cutting", 10)
	gm.update_station_score("cutting", 20)
	assert_eq(gm.current_pita_state["scores"]["cutting"], 20,
			  "Re-scoring a station should overwrite the old value")
	assert_eq(gm.current_pita_state["total_score"], 20)
	gm.free()


# ---------------------------------------------------------
# save_current_pita()
# These also work without the tree — save_current_pita()
# only modifies Global.daily_stats and completed_pitas.
# ---------------------------------------------------------
func test_save_current_pita_appends_to_completed() -> void:
	var gm = GameplayMasterScript.new()
	gm.current_pita_state = GameplayMasterScript._new_pita_state()
	gm.current_pita_state["meat_type"] = "pui"
	gm.save_current_pita()
	assert_eq(gm.completed_pitas.size(), 1, "Should have 1 completed pita")
	gm.free()

func test_save_current_pita_resets_state() -> void:
	var gm = GameplayMasterScript.new()
	gm.current_pita_state = GameplayMasterScript._new_pita_state()
	gm.current_pita_state["meat_type"] = "vita"
	gm.save_current_pita()
	assert_eq(gm.current_pita_state["meat_type"], "",
			  "After saving, current state should be a fresh pita")
	gm.free()

func test_save_perfect_pita_increments_perfect_orders() -> void:
	var gm = GameplayMasterScript.new()
	gm.current_pita_state = GameplayMasterScript._new_pita_state()
	gm.current_pita_state["total_score"] = 100
	var before: int = Global.daily_stats["perfect_orders"]
	gm.save_current_pita()
	assert_eq(Global.daily_stats["perfect_orders"], before + 1,
			  "A score of 100 should count as a perfect order")
	gm.free()

func test_save_pita_increments_customers_served() -> void:
	var gm = GameplayMasterScript.new()
	gm.current_pita_state = GameplayMasterScript._new_pita_state()
	var before: int = Global.daily_stats["customers_served"]
	gm.save_current_pita()
	assert_eq(Global.daily_stats["customers_served"], before + 1)
	gm.free()

func test_save_imperfect_pita_does_not_increment_perfect() -> void:
	var gm = GameplayMasterScript.new()
	gm.current_pita_state = GameplayMasterScript._new_pita_state()
	gm.current_pita_state["total_score"] = 80
	var before: int = Global.daily_stats["perfect_orders"]
	gm.save_current_pita()
	assert_eq(Global.daily_stats["perfect_orders"], before,
			  "A non-100 score should NOT be counted as perfect")
	gm.free()

func test_save_multiple_pitas() -> void:
	var gm = GameplayMasterScript.new()
	for i in 3:
		gm.current_pita_state = GameplayMasterScript._new_pita_state()
		gm.current_pita_state["meat_type"] = "pui"
		gm.save_current_pita()
	assert_eq(gm.completed_pitas.size(), 3)
	gm.free()


# ---------------------------------------------------------
# adauga_bacsis()  (tip accumulation)
# ---------------------------------------------------------
func test_adauga_bacsis_accumulates() -> void:
	var gm = GameplayMasterScript.new()
	gm.profit_ziua_curenta = 0.0
	gm.adauga_bacsis(10.0)
	gm.adauga_bacsis(5.5)
	assert_almost_eq(gm.profit_ziua_curenta, 15.5, 0.01,
					 "Tips should accumulate correctly")
	gm.free()
