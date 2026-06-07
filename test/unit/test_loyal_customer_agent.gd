extends GutTest

# =============================================================
# test_loyal_customer_agent.gd
# =============================================================


# ---------------------------------------------------------
# _fallback_dialogue()
# ---------------------------------------------------------
func test_fallback_with_empty_history_returns_intro() -> void:
	var agent := LoyalCustomerAgent.new()
	add_child_autofree(agent)
	await get_tree().process_frame

	var text: String = agent._fallback_dialogue([])
	assert_string_contains(text, "first visit")


func test_fallback_with_bad_score_mentions_mistake() -> void:
	var agent := LoyalCustomerAgent.new()
	add_child_autofree(agent)
	await get_tree().process_frame

	var history := [{"score": 40, "order": ["carne_pui"]}]
	var text: String = agent._fallback_dialogue(history)

	assert_string_contains(text, "wasn't great")


func test_fallback_with_good_score_is_positive() -> void:
	var agent := LoyalCustomerAgent.new()
	add_child_autofree(agent)
	await get_tree().process_frame

	var history := [{"score": 95, "order": ["carne_vita"]}]
	var text: String = agent._fallback_dialogue(history)

	assert_string_contains(text, "pretty good")


func test_fallback_uses_last_entry_not_first() -> void:
	var agent := LoyalCustomerAgent.new()
	add_child_autofree(agent)
	await get_tree().process_frame

	var history := [
		{"score": 30, "order": ["carne_pui"]},
		{"score": 90, "order": ["carne_vita"]}
	]

	var text: String = agent._fallback_dialogue(history)

	assert_string_contains(text, "pretty good")


func test_fallback_boundary_score_69_is_bad() -> void:
	var agent := LoyalCustomerAgent.new()
	add_child_autofree(agent)
	await get_tree().process_frame

	var history := [{"score": 69}]
	var text: String = agent._fallback_dialogue(history)

	assert_string_contains(text, "wasn't great")


func test_fallback_boundary_score_70_is_good() -> void:
	var agent := LoyalCustomerAgent.new()
	add_child_autofree(agent)
	await get_tree().process_frame

	var history := [{"score": 70}]
	var text: String = agent._fallback_dialogue(history)

	assert_string_contains(text, "pretty good")


# ---------------------------------------------------------
# _sanitize_dialogue()
# ---------------------------------------------------------
func test_sanitize_removes_non_ascii_characters() -> void:
	var agent := LoyalCustomerAgent.new()
	add_child_autofree(agent)
	await get_tree().process_frame

	var text := agent._sanitize_dialogue(
		"Hello nice shaorma! ★★★"
	)

	assert_false(text.contains("★"))


func test_sanitize_keeps_normal_text() -> void:
	var agent := LoyalCustomerAgent.new()
	add_child_autofree(agent)
	await get_tree().process_frame

	var original := "Hello, I remember your shaorma from last time."
	var text := agent._sanitize_dialogue(original)

	assert_eq(text, original)


func test_sanitize_limits_length() -> void:
	var agent := LoyalCustomerAgent.new()
	add_child_autofree(agent)
	await get_tree().process_frame

	var long_text := "a".repeat(300)
	var text := agent._sanitize_dialogue(long_text)

	assert_lte(text.length(), 180)


func test_sanitize_empty_returns_fallback() -> void:
	var agent := LoyalCustomerAgent.new()
	add_child_autofree(agent)
	await get_tree().process_frame

	var text := agent._sanitize_dialogue("")

	assert_ne(text, "")
	assert_true(text.length() > 0)


func test_sanitize_only_symbols_returns_fallback() -> void:
	var agent := LoyalCustomerAgent.new()
	add_child_autofree(agent)
	await get_tree().process_frame

	var text := agent._sanitize_dialogue("★★★@@@###")

	assert_ne(text, "")
	assert_true(text.length() > 0)
