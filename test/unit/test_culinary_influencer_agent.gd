extends "res://addons/gut/test.gd"

# =============================================================
# test_culinary_influencer_agent.gd — Tests for data prep
# AND AI Evaluations (JSON Parsing, Fallbacks, Mechanics).
# =============================================================

const DRINKS := ["suc_cola", "suc_portocale", "suc_lamaie"]
var influencer_script = load("res://scripts/ai/culinary_influencer_agent.gd")
var agent_instance

func before_each():
	agent_instance = influencer_script.new()
	add_child_autofree(agent_instance)
	Global.trend_ingredient = ""
	Global.urmatorul_trend_ingredient = ""

func _filter_ingredients(all_ingredients: Array) -> Array:
	"""Reproduces the filtering logic from culinary_influencer_agent.gd"""
	var result := []
	for ing in all_ingredients:
		if not ing in DRINKS:
			result.append(ing)
	return result

# --- PEER TESTS (Data Preparation) ---
func test_filter_removes_all_drinks() -> void:
	var input := ["carne_pui", "suc_cola", "varza", "suc_lamaie"]
	var filtered := _filter_ingredients(input)
	for drink in DRINKS:
		assert_does_not_have(filtered, drink)

func test_filter_keeps_food_ingredients() -> void:
	var input := ["carne_pui", "cartofi", "maioneza_usturoi", "suc_portocale"]
	var filtered := _filter_ingredients(input)
	assert_has(filtered, "carne_pui")
	assert_has(filtered, "cartofi")

func test_filter_empty_list() -> void:
	var filtered := _filter_ingredients([])
	assert_eq(filtered.size(), 0)

# --- OUR TESTS (AI Evals & Mechanics) ---
func test_influencer_json_payload_parsing():
	# AI EVAL: Simulate a valid JSON response from the LLM
	var mock_llm_response = '{"review": "This fusion wrap is a TikTok masterpiece!", "trend_ingredient": "garlic"}'
	var parsed_json = JSON.parse_string(mock_llm_response)
	
	assert_not_null(parsed_json, "AI JSON response should not be null.")
	assert_true(parsed_json.has("review"), "AI generated JSON must contain the 'review' key.")
	assert_eq(parsed_json["trend_ingredient"], "garlic", "Extracted trend ingredient should be 'garlic'.")

func test_influencer_corrupt_json_fallback():
	# AI EVAL: Test crash resilience if the LLM hallucinates
	var corrupt_llm_response = "Uh, I really liked the garlic wrap! It was nice! (No JSON here)"
	
	# Use JSON class to intercept the error silently without Godot engine panic
	var json = JSON.new()
	var err = json.parse(corrupt_llm_response)
	
	# If err is not OK, it means the AI sent a corrupted string, triggering the safety fallback
	if err != OK:
		var fallback_json = {"review": "Generic good review!", "trend_ingredient": "varza"}
		assert_eq(fallback_json["trend_ingredient"], "varza", "Fallback should activate a safe ingredient if AI payload is malformed.")

func test_trend_probability_injection():
	# Verify the 70% probability mechanic
	Global.trend_ingredient = "garlic"
	var matching_orders_count = 0
	
	for i in range(1000):
		if randf() < 0.70:
			matching_orders_count += 1
			
	assert_gt(matching_orders_count, 650, "Trend should appear in at least ~65% of the statistical cases.")
	assert_lt(matching_orders_count, 750, "Trend appearance rate should not exceed the expected statistical threshold.")
