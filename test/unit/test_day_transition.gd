extends GutTest

# =============================================================
# test_day_transition.gd — Unit tests for the DayTransition
# script's constants and enum definitions.
#
# The full scene requires many UI nodes, so we test what can
# be verified without instantiating the scene: constants,
# enum values, and the default day duration.
# =============================================================

const DayTransitionScript = preload("res://scripts/day_management/day_transition.gd")


# ---------------------------------------------------------
# Constants
# ---------------------------------------------------------
func test_default_day_duration_is_three_minutes() -> void:
	assert_eq(DayTransitionScript.DEFAULT_DAY_DURATION, 180.0,
			  "Default day should last 180 seconds (3 minutes)")

func test_gameplay_scene_path_is_valid() -> void:
	assert_true(ResourceLoader.exists(DayTransitionScript.GAMEPLAY_SCENE),
				"GAMEPLAY_SCENE path should point to an existing resource")


# ---------------------------------------------------------
# DayState enum
# ---------------------------------------------------------
func test_day_state_enum_has_morning_and_night() -> void:
	# Enums in GDScript are just ints — MORNING=0, NIGHT=1
	assert_eq(DayTransitionScript.DayState.MORNING, 0)
	assert_eq(DayTransitionScript.DayState.NIGHT, 1)
