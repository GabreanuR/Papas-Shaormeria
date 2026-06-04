extends GutTest

# =============================================================
# test_culinary_influencer_agent.gd — Tests for the ingredient
# filtering logic in generate_review().
#
# We test the drink-filtering behaviour by reproducing the
# inline logic from the script. The actual HTTP call is NOT
# triggered — we only care about data preparation.
# =============================================================

const DRINKS := ["suc_cola", "suc_portocale", "suc_lamaie"]


func _filter_ingredients(all_ingredients: Array) -> Array:
	"""Reproduces the filtering logic from culinary_influencer_agent.gd"""
	var result := []
	for ing in all_ingredients:
		if not ing in DRINKS:
			result.append(ing)
	return result


# ---------------------------------------------------------
# Drink filtering
# ---------------------------------------------------------
func test_filter_removes_all_drinks() -> void:
	var input := ["carne_pui", "suc_cola", "varza", "suc_lamaie"]
	var filtered := _filter_ingredients(input)
	for drink in DRINKS:
		assert_does_not_have(filtered, drink,
							"'%s' should be removed from the list" % drink)

func test_filter_keeps_food_ingredients() -> void:
	var input := ["carne_pui", "cartofi", "maioneza_usturoi", "suc_portocale"]
	var filtered := _filter_ingredients(input)
	assert_has(filtered, "carne_pui")
	assert_has(filtered, "cartofi")
	assert_has(filtered, "maioneza_usturoi")

func test_filter_empty_list() -> void:
	var filtered := _filter_ingredients([])
	assert_eq(filtered.size(), 0)

func test_filter_only_drinks_returns_empty() -> void:
	var filtered := _filter_ingredients(DRINKS.duplicate())
	assert_eq(filtered.size(), 0,
			  "If only drinks are given, result should be empty")

func test_filter_no_drinks_returns_all() -> void:
	var input := ["carne_vita", "ceapa", "rosii"]
	var filtered := _filter_ingredients(input)
	assert_eq(filtered.size(), 3)
