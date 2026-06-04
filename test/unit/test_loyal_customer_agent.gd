extends GutTest

# =============================================================
# test_loyal_customer_agent.gd — Tests for fallback dialogue
# and offline behaviour of LoyalCustomerAgent.
# =============================================================


# ---------------------------------------------------------
# _fallback_dialogue()
# ---------------------------------------------------------
func test_fallback_with_empty_history_returns_intro() -> void:
	var agent := LoyalCustomerAgent.new()
	add_child_autofree(agent)
	await get_tree().process_frame

	var text: String = agent._fallback_dialogue([])
	assert_string_contains(text, "first visit",
						   "Empty history should trigger the intro dialogue")

func test_fallback_with_bad_score_mentions_mistake() -> void:
	var agent := LoyalCustomerAgent.new()
	add_child_autofree(agent)
	await get_tree().process_frame

	var history := [{"score": 40, "order": ["carne_pui"]}]
	var text: String = agent._fallback_dialogue(history)
	assert_string_contains(text, "wasn't great",
						   "Low score should mention a bad experience")

func test_fallback_with_good_score_is_positive() -> void:
	var agent := LoyalCustomerAgent.new()
	add_child_autofree(agent)
	await get_tree().process_frame

	var history := [{"score": 95, "order": ["carne_vita"]}]
	var text: String = agent._fallback_dialogue(history)
	assert_string_contains(text, "pretty good",
						   "High score should result in a positive fallback")

func test_fallback_uses_last_entry_not_first() -> void:
	var agent := LoyalCustomerAgent.new()
	add_child_autofree(agent)
	await get_tree().process_frame

	# First visit was bad, but the last one was good.
	var history := [
		{"score": 30, "order": ["carne_pui"]},
		{"score": 90, "order": ["carne_vita"]}
	]
	var text: String = agent._fallback_dialogue(history)
	# Should reflect the LAST entry (90 = good).
	assert_string_contains(text, "pretty good")

func test_fallback_boundary_score_69_is_bad() -> void:
	var agent := LoyalCustomerAgent.new()
	add_child_autofree(agent)
	await get_tree().process_frame

	var history := [{"score": 69}]
	var text: String = agent._fallback_dialogue(history)
	assert_string_contains(text, "wasn't great",
						   "Score 69 (< 70) should be considered a bad order")

func test_fallback_boundary_score_70_is_good() -> void:
	var agent := LoyalCustomerAgent.new()
	add_child_autofree(agent)
	await get_tree().process_frame

	var history := [{"score": 70}]
	var text: String = agent._fallback_dialogue(history)
	assert_string_contains(text, "pretty good",
						   "Score exactly 70 should NOT be treated as bad")
