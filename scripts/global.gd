extends Node

# La începutul global.gd, forțează includerea în export
const _PRELOAD_TRES_1 = preload("res://assets/theme/booklet.tres")
const _PRELOAD_TRES_2 = preload("res://assets/theme/global_ui_theme.tres")
const _PRELOAD_TRES_3 = preload("res://assets/theme/light_texture.tres")
const _PRELOAD_TRES_4 = preload("res://assets/theme/panel_style.tres")
const _PRELOAD_TRES_5 = preload("res://assets/theme/buttons/button_hover.tres")
const _PRELOAD_TRES_6 = preload("res://assets/theme/buttons/button_normal.tres")
const _PRELOAD_TRES_7 = preload("res://assets/theme/buttons/button_pressed.tres")
const _PRELOAD_TRES_8 = preload("res://assets/theme/settings_ui/grabber_hover.tres")
const _PRELOAD_TRES_9 = preload("res://assets/theme/settings_ui/grabber_normal.tres")
const _PRELOAD_TRES_10 = preload("res://assets/theme/settings_ui/toggle_off.tres")
const _PRELOAD_TRES_11 = preload("res://assets/theme/settings_ui/toggle_on.tres")
const _PRELOAD_TRES_12 = preload("res://assets/theme/slot_buttons/empty_slot.tres")
const _PRELOAD_TRES_13 = preload("res://assets/theme/slot_buttons/empty_slot_hover.tres")
const _PRELOAD_TRES_14 = preload("res://assets/theme/slot_buttons/fiiled_slot_hover.tres")
const _PRELOAD_TRES_15 = preload("res://assets/theme/slot_buttons/fiiled_slot_normal.tres")
const _PRELOAD_TRES_16 = preload("res://assets/theme/slot_buttons/filled_slot_pressed.tres")

# ---------------------------------------------------------
# 1. SIGNALS
# ---------------------------------------------------------
signal day_ended
signal money_changed(new_amount: float)
## Emitted every time the daily cash register changes — for the in-game HUD.
signal daily_earnings_changed(amount: float)
## Emitted when the day counter advances so UI components can update reactively.
signal day_changed(new_day: int)
signal achievement_unlocked(id: String)
signal equipped_item_changed(item_id: String)

# ---------------------------------------------------------
# 2. ENUMS
# ---------------------------------------------------------

# ---------------------------------------------------------
# 3. CONSTANTS
# ---------------------------------------------------------
const SAVE_DIR := "user://saves/"
const SAVE_FILE_TEMPLATE := "user://saves/save_slot_%d.json"
const MAX_SAVE_SLOTS := 3
const DEFAULT_STARTING_MONEY := 150.0
const ACHIEVEMENTS_DATA = {
	"first_bite": {"title": "First Bite", "desc": "Serve your very first customer."},
	"perfectionist": {"title": "Perfectionist", "desc": "Achieve 5 perfect orders (100 score)."},
	"rolling_in_dough": {"title": "Rolling in Dough", "desc": "Accumulate $500.00 in your wallet."},
	"night_owl": {"title": "Night Owl", "desc": "Survive and complete the first 3 days."},
	"influencers_choice": {"title": "Influencer's Choice", "desc": "Successfully serve a Culinary Influencer."},
	"familiar_faces": {"title": "Familiar Faces", "desc": "Successfully serve a Loyal Customer."},
	"fusion_master": {"title": "Fusion Master", "desc": "Serve an order matching the Daily Fusion Recipe."},
	"oops": {"title": "Oops...", "desc": "Serve a bad order with a score below 50."},
	"crowd_pleaser": {"title": "Crowd Pleaser", "desc": "Serve a total milestone of 20 customers."},
	"kitchen_disaster": {"title": "Kitchen Disaster", "desc": "Get an absolute score of 0 on an order."},
	"speedrun_champion": {"title": "Speed Demon", "desc": "Serve 5 perfect orders in under 5 minutes in Arcade Mode."}
}

## Item shop database — prices and gameplay buff identifiers.
## Each buff_type maps to a specific multiplier in the Customer script.
const ITEMS_DATA := {
	"laser_glasses": {
		"title": "Laser Glasses",
		"desc": "Decreases cooking time by 50%.",
		"price": 200.0,
		"buff_type": "cooking_speed",
		"buff_value": 0.5,
		"node_name": "LaserGlasses"
	},
	"angel_wings": {
		"title": "Angel Wings",
		"desc": "Increases tips by 50%.",
		"price": 300.0,
		"buff_type": "tips_boost",
		"buff_value": 1.5,
		"node_name": "AngelWings"
	},
	"super_shoes": {
		"title": "Super Shoes",
		"desc": "Increases customer patience by 100%.",
		"price": 250.0,
		"buff_type": "patience_boost",
		"buff_value": 2.0,
		"node_name": "SuperShoes"
	}
}

## Upgrade shop database — max level is 3. 
## Price index 0 is empty because level 1 is free (default).
const UPGRADES_DATA := {
	"grill": {
		"title": "Grill Master",
		"desc": "Carnea se prăjește mult mai repede.",
		"max_level": 3,
		"prices": [0, 100, 250],   # Cât costă să treci la nivelul 2, respectiv 3
		"buffs": [1.0, 0.8, 0.6]   # 100% (normal), 80% timp, 60% timp
	},
	"oven": {
		"title": "Turbo Oven",
		"desc": "Lipia se încălzește instantaneu.",
		"max_level": 3,
		"prices": [0, 200, 300],
		"buffs": [1.0, 0.85, 0.7]  # Multiplicator pentru durata de stat pe foc
	},
	"bell": {
		"title": "Golden Bell",
		"desc": "Clienții așteaptă cu 50% mai mult.",
		"max_level": 3,
		"prices": [0, 120, 240],
		"buffs": [1.0, 1.25, 1.5]  # Multiplicator pentru răbdare
	}
}

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

var trend_ingredient: String = ""
var urmatorul_trend_ingredient: String = ""
var daily_fusion_recipe: Array = []

# ---------------------------------------------------------
# ARCADE MODE (SPEEDRUN)
# ---------------------------------------------------------
var is_arcade_mode: bool = false
var arcade_played_today: bool = false
var arcade_perfect_orders: int = 0
var arcade_customers_served: int = 0
var _arcade_finished: bool = false

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
	# Creăm folderul de salvări dacă nu există
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)
		
	_day_timer = Timer.new()
	_day_timer.one_shot = true
	_day_timer.timeout.connect(_on_day_timer_ended)
	add_child(_day_timer)
	
	# Încărcăm automat Salvarea 1 la deschiderea jocului (pentru debugging)
	var path_salvare = SAVE_FILE_TEMPLATE % 1
	if FileAccess.file_exists(path_salvare):
		var file = FileAccess.open(path_salvare, FileAccess.READ)
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data = json.get_data()
			load_save_data(1, data)
		file.close()
	else:
		current_save = get_default_save_data()

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
		"equipment_levels": {
			"grill": 1,
			"oven": 1,
			"bell": 1
		},
		"customization": {
			"unlocked_items": [],
			"equipped_items": []
		},
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

## Clears daily statistics at the start of each morning
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
	is_arcade_mode = false
	is_night = false
	reset_daily_stats() # Call the new reset function here!
	_day_timer.stop()

func start_arcade_mode() -> void:
	is_arcade_mode = true
	arcade_played_today = true
	arcade_perfect_orders = 0
	arcade_customers_served = 0
	_arcade_finished = false
	
	is_night = false
	reset_daily_stats() 
	_day_timer.start(300.0)

func register_arcade_order(score: int) -> void:
	if not is_arcade_mode or _arcade_finished:
		return
		
	arcade_customers_served += 1
	
	if score >= 80:
		arcade_perfect_orders += 1
	else:
		# EȘEC IMEDIAT: Oprim totul cum a greșit o comandă!
		_arcade_finished = true 
		_day_timer.stop()
		_arata_ecran_final_arcade("CHALLENGE FAILED", "You ruined an order! Score dropped below 80%.", false)
		return # Ieșim din funcție, nu mai verificăm altceva
		
	if arcade_customers_served >= 5:
		_arcade_finished = true 
		_day_timer.stop()
		
		unlock_achievement("speedrun_champion")
		current_save["money"] += 100.0
		money_changed.emit(current_save["money"])
		save_game_to_disk()
		_arata_ecran_final_arcade("CHALLENGE COMPLETE!", "You earned the Speed Demon Trophy and $100!", true)

# Funcția care desenează Pop-up-ul la final de provocare
func _arata_ecran_final_arcade(titlu: String, mesaj: String, succes: bool) -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 250 # Îl punem peste absolut tot jocul
	add_child(canvas)
	
	var blocker = ColorRect.new()
	blocker.color = Color(0, 0, 0, 0.6) # Întunecă dramatic ecranul din spate
	blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP # OPREȘTE complet orice click în joc
	canvas.add_child(blocker)

	var panel = PanelContainer.new()
	var stil = StyleBoxFlat.new()
	stil.bg_color = Color(0.12, 0.12, 0.12, 0.98) # Negru mat
	stil.border_width_left = 6; stil.border_width_top = 6; stil.border_width_right = 6; stil.border_width_bottom = 6
	stil.border_color = Color(0.2, 0.8, 0.2) if succes else Color(0.8, 0.2, 0.2) # Verde pt succes, Roșu pt eșec
	stil.set_corner_radius_all(15)
	stil.set_content_margin_all(40)
	panel.add_theme_stylebox_override("panel", stil)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)

	var lbl_titlu = Label.new()
	lbl_titlu.text = titlu
	lbl_titlu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_titlu.add_theme_font_size_override("font_size", 48)
	lbl_titlu.add_theme_color_override("font_color", Color(0.95, 0.85, 0.2) if succes else Color(1.0, 1.0, 1.0))

	var lbl_mesaj = Label.new()
	lbl_mesaj.text = mesaj
	lbl_mesaj.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_mesaj.add_theme_font_size_override("font_size", 24)

	vbox.add_child(lbl_titlu)
	vbox.add_child(lbl_mesaj)
	panel.add_child(vbox)
	canvas.add_child(panel)

	# Îl centrăm perfect pe ecran
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

	# Așteptăm 4 secunde ca jucătorul să vadă rezultatul
	await get_tree().create_timer(10.0).timeout
	canvas.queue_free()

	# Acum trimitem semnalul care îl aruncă înapoi în Hub!
	day_ended.emit()

## Advances the day counter by one and resets the night flag.
## Always use this instead of writing to current_save["day"] directly,
## so that all listeners (e.g. TopBar) are notified via day_changed.
func advance_day() -> void:
	current_save["day"] += 1
	if int(current_save["day"]) % 7 == 0:
		current_save["money"] += 100
		money_changed.emit(current_save["money"])
	is_night = false
	save_game_to_disk() # Salvăm faptul că am trecut la o zi nouă!
	day_changed.emit(current_save["day"])

## Called from the Main Menu when creating or loading a game.
## Merges loaded data on top of defaults so that old saves missing new keys
## still have sensible values (forward-compatible saves).
func load_save_data(slot_id: int, parsed_data: Dictionary) -> void:
	active_slot_id = slot_id
	var defaults = Global.get_default_save_data()
	defaults.merge(parsed_data, true)  # parsed_data wins on conflicts
	current_save = defaults
	
## Finalizează ziua, adaugă câștigul de azi la totalul permanent
func end_day_and_save_earnings() -> void:
	current_save["money"] += daily_earnings
	
	# Acum chemăm salvarea reală!
	save_game_to_disk() 
	
	daily_earnings = 0.0
	daily_earnings_changed.emit(daily_earnings)
	
## Salvează datele curente fizic pe hard disk
func save_game_to_disk() -> void:
	# Salvăm mereu pe slotul activ (sau pe slotul 1 default)
	var slot = active_slot_id if active_slot_id > 0 else 1
	var path = SAVE_FILE_TEMPLATE % slot
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(current_save))
		file.close()
		
## Unlocks an achievement by ID, saves progress to disk, and emits a signal.
func unlock_achievement(id: String) -> void:
	# Verificăm dacă NU este deja deblocat
	if not current_save["achievements"].has(id) or current_save["achievements"][id] == false:
		current_save["achievements"][id] = true
		
		# Declanșăm animația de notificare!
		if ACHIEVEMENTS_DATA.has(id):
			if AudioManager.achievement_sfx:
				AudioManager.play_sfx(AudioManager.achievement_sfx)
			_arata_notificare_trofeu(ACHIEVEMENTS_DATA[id]["title"])
			
func _arata_notificare_trofeu(titlu_trofeu: String) -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 200 # Strat foarte înalt ca să apară peste orice
	add_child(canvas) # Îl legăm direct de Global
	
	var panel = PanelContainer.new()
	var stil = StyleBoxFlat.new()
	stil.bg_color = Color(0.12, 0.12, 0.12, 0.95) # Gri închis elegant
	stil.border_color = Color(0.95, 0.75, 0.2, 1.0) # Margine aurie
	stil.border_width_left = 3; stil.border_width_top = 3; stil.border_width_right = 3; stil.border_width_bottom = 3
	stil.set_corner_radius_all(10)
	stil.set_content_margin_all(15)
	panel.add_theme_stylebox_override("panel", stil)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var icon_lbl = Label.new()
	icon_lbl.text = "🏆"
	icon_lbl.add_theme_font_size_override("font_size", 36)
	
	var vbox = VBoxContainer.new()
	var subtitlu = Label.new()
	subtitlu.text = "ACHIEVEMENT UNLOCKED"
	subtitlu.add_theme_font_size_override("font_size", 12)
	subtitlu.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	
	var titlu = Label.new()
	titlu.text = titlu_trofeu
	titlu.add_theme_font_size_override("font_size", 18)
	titlu.add_theme_color_override("font_color", Color(0.95, 0.75, 0.2)) # Auriu
	
	vbox.add_child(subtitlu)
	vbox.add_child(titlu)
	
	hbox.add_child(icon_lbl)
	hbox.add_child(vbox)
	panel.add_child(hbox)
	canvas.add_child(panel)
	
	# O punem în afara ecranului în dreapta sus
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.position = Vector2(1920, 60) # Ascunsă inițial după marginea din dreapta
	panel.size = Vector2(320, 80)
	
	# Magia mișcării (Tween)
	var tween = create_tween()
	# Intră pe ecran cu un mic efect de "bounce" (recul)
	tween.tween_property(panel, "position:x", 1920 - 350, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Stă pe ecran 4 secunde ca să poată fi citită
	tween.tween_interval(4.0)
	# Iese de pe ecran glisând înapoi
	tween.tween_property(panel, "position:x", 1920, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	# Când termină, curăță tot din memorie
	tween.finished.connect(canvas.queue_free)

## Helper function to check if a specific achievement is unlocked.
func is_achievement_unlocked(achievement_id: String) -> bool:
	if current_save.has("achievements") and current_save["achievements"].has(achievement_id):
		return current_save["achievements"][achievement_id]
	return false

# ---------------------------------------------------------
# 9. ITEM SHOP & CUSTOMIZATION
# ---------------------------------------------------------

## Returns true if the player owns the given item.
func is_item_unlocked(item_id: String) -> bool:
	var items: Array = current_save.get("customization", {}).get("unlocked_items", [])
	return item_id in items

## Returns the list of currently equipped item IDs.
func get_equipped_items() -> Array:
	return current_save.get("customization", {}).get("equipped_items", [])

## Returns true if a specific item is currently equipped.
func is_item_equipped(item_id: String) -> bool:
	return item_id in get_equipped_items()

## Legacy helper — returns the first equipped item or "" (for scripts that
## only care about a single item).
func get_equipped_item() -> String:
	var items := get_equipped_items()
	return items[0] if items.size() > 0 else ""

## Attempts to purchase an item. Returns true on success.
func purchase_item(item_id: String) -> bool:
	if not ITEMS_DATA.has(item_id):
		push_error("Item '%s' does not exist in ITEMS_DATA." % item_id)
		return false

	if is_item_unlocked(item_id):
		push_warning("Item '%s' is already unlocked." % item_id)
		return false

	var price: float = ITEMS_DATA[item_id]["price"]
	if current_save["money"] < price:
		return false

	current_save["money"] -= price
	money_changed.emit(current_save["money"])

	_ensure_customization_dict()
	current_save["customization"]["unlocked_items"].append(item_id)
	save_game_to_disk()
	return true

## Equips an owned item (additive — multiple items can be worn).
func equip_item(item_id: String) -> void:
	if not is_item_unlocked(item_id):
		push_error("Cannot equip '%s': not unlocked." % item_id)
		return

	_ensure_customization_dict()

	var equipped: Array = current_save["customization"]["equipped_items"]
	if item_id not in equipped:
		equipped.append(item_id)

	equipped_item_changed.emit(item_id)
	save_game_to_disk()

## Unequips a specific item.
func unequip_item(item_id: String = "") -> void:
	_ensure_customization_dict()

	var equipped: Array = current_save["customization"]["equipped_items"]

	if item_id == "":
		# Legacy call — clear everything
		equipped.clear()
	else:
		equipped.erase(item_id)

	equipped_item_changed.emit("")
	save_game_to_disk()

## Ensures the customization sub-dictionary has the correct structure.
func _ensure_customization_dict() -> void:
	if not current_save.has("customization"):
		current_save["customization"] = {"unlocked_items": [], "equipped_items": []}
	if not current_save["customization"].has("unlocked_items"):
		current_save["customization"]["unlocked_items"] = []
	if not current_save["customization"].has("equipped_items"):
		current_save["customization"]["equipped_items"] = []

## Returns the gameplay multiplier for a given buff_type.
## Checks ALL equipped items — returns the buff if any match.
func get_buff_multiplier(buff_type: String) -> float:
	for item_id in get_equipped_items():
		if ITEMS_DATA.has(item_id):
			var item_data: Dictionary = ITEMS_DATA[item_id]
			if item_data["buff_type"] == buff_type:
				return item_data["buff_value"]
	return 1.0

## Convenience shortcuts used by Customer and other gameplay scripts.
func get_cooking_multiplier() -> float:
	return get_buff_multiplier("cooking_speed")

func get_tips_multiplier() -> float:
	return get_buff_multiplier("tips_boost")

func get_patience_multiplier() -> float:
	var haine_buff = get_buff_multiplier("patience_boost")
	var bell_buff = get_upgrade_buff("bell") 
	return haine_buff * bell_buff

# ---------------------------------------------------------
# 10. SIGNAL CALLBACKS
# ---------------------------------------------------------
func _on_day_timer_ended() -> void:
	if is_arcade_mode:
		if _arcade_finished: return
		_arcade_finished = true
		_arata_ecran_final_arcade("TIME'S UP!", "You ran out of time! You only served %d customers." % arcade_customers_served, false)
	else:
		pass
	# NOTE: Scene navigation is intentionally NOT done here.
	# GameplayMaster listens to `day_ended` and handles the scene transition,
	# keeping Global free of any scene-flow responsibilities.

# ---------------------------------------------------------
# 11. UPGRADES SYSTEM (Echipamente Bucătărie)
# ---------------------------------------------------------

## Returnează nivelul curent al unui echipament (default 1).
func get_upgrade_level(upgrade_id: String) -> int:
	if current_save.has("equipment_levels") and current_save["equipment_levels"].has(upgrade_id):
		return current_save["equipment_levels"][upgrade_id]
	return 1 # Fallback la nivel 1 dacă nu există în salvare

## Cumpără următorul nivel dacă jucătorul are suficienți bani.
func purchase_upgrade(upgrade_id: String) -> bool:
	if not UPGRADES_DATA.has(upgrade_id):
		return false
		
	var current_lvl = get_upgrade_level(upgrade_id)
	var max_lvl = UPGRADES_DATA[upgrade_id]["max_level"]
	
	# Dacă e deja la maxim, nu mai poate cumpăra
	if current_lvl >= max_lvl:
		return false
		
	# array-ul "prices" are index 1 pentru Trecerea la Nivel 2. 
	# (Index 0 este dummy pentru nivelul 1)
	var pret = UPGRADES_DATA[upgrade_id]["prices"][current_lvl]
	
	if current_save["money"] >= pret:
		current_save["money"] -= pret
		money_changed.emit(current_save["money"])
		
		# Creștem nivelul și salvăm fizic
		if not current_save.has("equipment_levels"):
			current_save["equipment_levels"] = {}
		current_save["equipment_levels"][upgrade_id] = current_lvl + 1
		save_game_to_disk()
		return true
		
	return false

## Returnează multiplicatorul (buff-ul) specific nivelului curent.
func get_upgrade_buff(upgrade_id: String) -> float:
	var lvl = get_upgrade_level(upgrade_id)
	# Scădem 1 din nivel pentru a accesa indexul corect din array-ul buffs (0, 1 sau 2)
	var index_array = clamp(lvl - 1, 0, 2)
	return UPGRADES_DATA[upgrade_id]["buffs"][index_array]
