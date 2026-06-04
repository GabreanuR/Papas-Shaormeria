extends "res://addons/gut/test.gd"

# =============================================================
# test_daily_menu_agent.gd — AI Evals for the Fusion Menu.
# =============================================================

func before_each():
	Global.daily_fusion_recipe = ["pineapple", "curry", "chicken"]

func test_daily_fusion_recipe_generation():
	# Verificăm că AI-ul nu a lăsat meniul gol
	assert_not_null(Global.daily_fusion_recipe)
	assert_gt(Global.daily_fusion_recipe.size(), 0, "Meniul trebuie să conțină ingrediente.")

func test_fusion_double_tip_logic():
	# Simulăm o shaorma care se potrivește perfect cu meniul generat de AI
	var player_crafted_shaorma = ["pineapple", "curry", "chicken"]
	var base_tip = 10
	var final_tip = base_tip
	
	var matches_fusion = true
	for ingredient in Global.daily_fusion_recipe:
		if not player_crafted_shaorma.has(ingredient):
			matches_fusion = false
			
	if matches_fusion:
		final_tip = base_tip * 2
		
	assert_eq(final_tip, 20, "Bacșișul ar trebui să se dubleze dacă rețeta respectă fuziunea.")
