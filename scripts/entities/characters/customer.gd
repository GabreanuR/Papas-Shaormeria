extends Node2D

const CustomerHistoryScript = preload("res://scripts/ai/customer_history.gd")

var is_loyal_customer := false

var ai_dialogue_ready_text: String = ""
var ai_dialogue_is_ready: bool = false

@onready var sprite = $Sprite2D
@onready var buton_comanda = $TextureButton
@onready var _laser_glasses: Sprite2D = get_node_or_null("Sprite2D/LaserGlasses")
@onready var _angel_wings: Sprite2D = get_node_or_null("Sprite2D/AngelWings")
@onready var _super_shoes: Sprite2D = get_node_or_null("Sprite2D/SuperShoes")

var textura_lobby: Texture2D
var textura_zoom: Texture2D
var id_unic: int = 0

var comanda_mea: Array = []

signal a_fost_apasat(ingrediente)
signal patience_expired

var a_dat_comanda: bool = false 

@export var rabdare_maxima: float = 100.0
@export var rata_scadere_coada: float = 1.0
@export var rata_scadere_gatit: float = 0.01

var rabdare_curenta: float = rabdare_maxima
var scade_rabdare: bool = true 
var rata_curenta: float = rata_scadere_coada

var legume_disponibile: Array = [
	"ardei", "cartofi", "castraveti_murati", "ceapa", 
	"chilli_flakes", "rosii", "salata", "varza", "jalapenos", "falafel"
]

var sosuri_disponibile: Array = [
	"ketchup_dulce", "ketchup_picant", "maioneza", 
	"maioneza_picanta", "maioneza_usturoi"
]

var sucuri_disponibile: Array = [
	"suc_cola", "suc_portocale", "suc_lamaie"
]


func _ready():
	if textura_lobby != null:
		sprite.texture = textura_lobby

	_apply_equipped_accessories()
	
	# Listen for changes so the Paper Doll updates instantly in the HUB
	if not Global.equipped_item_changed.is_connected(_on_equipped_item_changed):
		Global.equipped_item_changed.connect(_on_equipped_item_changed)

	pregateste_client_nou()
	pornește_animatie_buton()


func genereaza_comanda_random():
	comanda_mea = ["lipie"]
	
	var tipuri_carne = ["carne_pui", "carne_vita"]
	comanda_mea.append(tipuri_carne.pick_random())
	
	var legume_amestecate = legume_disponibile.duplicate()
	legume_amestecate.shuffle()
	var numar_legume = randi_range(2, 4)

	for i in range(numar_legume):
		comanda_mea.append(legume_amestecate[i])
		
	var sosuri_amestecate = sosuri_disponibile.duplicate()
	sosuri_amestecate.shuffle()
	var numar_sosuri = randi_range(1, 2)

	for i in range(numar_sosuri):
		comanda_mea.append(sosuri_amestecate[i])
		
	var sucul_ales = sucuri_disponibile.pick_random()
	comanda_mea.append(sucul_ales)
	
	if Global.trend_ingredient != "" and randf() <= 0.7: 
		if not comanda_mea.has(Global.trend_ingredient):
			
			# Verificăm dacă ingredientul trendy este sos sau băutură
			var este_sos_sau_bautura: bool = false
			
			var lista_lichide = ["ketchup_dulce", "ketchup_picant", "maioneza", "maioneza_picanta", "maioneza_usturoi"]
			
			if Global.trend_ingredient in lista_lichide:
				este_sos_sau_bautura = true
			
			# Aplicăm poziționarea pe bilet în funcție de tip
			if este_sos_sau_bautura:
				# Dacă e sos/băutură, îl punem la final, dar chiar ÎNAINTE de ultima băutură (poziția penultimă)
				var pozitie_inserare = max(0, comanda_mea.size() - 1)
				comanda_mea.insert(pozitie_inserare, Global.trend_ingredient)
			else:
				# Dacă e ingredient solid (carne, cartofi, ceapă), îl punem la început, după carne (poziția 2)
				comanda_mea.insert(2, Global.trend_ingredient)


func pregateste_client_nou():
	genereaza_comanda_random()
	a_dat_comanda = false
	
	var rabdare_initiala := rabdare_maxima * Global.get_patience_multiplier()

	if is_loyal_customer and CustomerHistoryScript.last_order_was_wrong():
		rabdare_initiala *= 0.9
	
	rabdare_curenta = rabdare_initiala
	rata_curenta = rata_scadere_coada
	scade_rabdare = true
	set_process(true)


func seteaza_sprite_comanda():
	if textura_zoom != null:
		sprite.texture = textura_zoom
		_apply_equipped_accessories()


func seteaza_sprite_lobby():
	if textura_lobby != null:
		sprite.texture = textura_lobby
		_apply_equipped_accessories()


func pornește_animatie_buton():
	var pozitie_initiala = buton_comanda.position
	var tween = create_tween().set_loops()
	
	tween.tween_property(
		buton_comanda,
		"position:y",
		pozitie_initiala.y - 10,
		1.0
	).set_trans(Tween.TRANS_SINE)
	
	tween.tween_property(
		buton_comanda,
		"position:y",
		pozitie_initiala.y,
		1.0
	).set_trans(Tween.TRANS_SINE)


func _process(delta):
	if scade_rabdare and rabdare_curenta > 0:
		rabdare_curenta -= rata_curenta * delta
		
		if rabdare_curenta <= 0:
			rabdare_curenta = 0
			scade_rabdare = false
			set_process(false)
			patience_expired.emit()


func _on_texture_button_pressed():
	if a_dat_comanda == false:
		rata_curenta = rata_scadere_gatit
		seteaza_sprite_comanda()
		a_fost_apasat.emit(comanda_mea)
		a_dat_comanda = true

# ---------------------------------------------------------
# ITEM CUSTOMIZATION (Paper Doll)
# ---------------------------------------------------------

## Hides all accessory sprites, then shows those that are currently
## equipped in Global. Called once in _ready().
func _apply_equipped_accessories() -> void:
	# Hide everything first
	if _laser_glasses:
		_laser_glasses.hide()
	if _angel_wings:
		_angel_wings.hide()
	if _super_shoes:
		_super_shoes.hide()

	# Condiție strictă: Accesoriile sunt desenate DOAR pe Papa Louie (textura întreagă)
	if sprite == null or sprite.texture == null:
		return
	var tex_name = sprite.texture.resource_path.get_file()
	if tex_name != "papalouie.png":
		return

	# Show each equipped item
	for item_id in Global.get_equipped_items():
		if not Global.ITEMS_DATA.has(item_id):
			continue
		var node_name: String = Global.ITEMS_DATA[item_id]["node_name"]
		# Trebuie să căutăm în copilul Sprite2D
		var accessory := get_node_or_null("Sprite2D/" + node_name) as Sprite2D
		if accessory:
			accessory.show()

func _on_equipped_item_changed(_item_id: String) -> void:
	_apply_equipped_accessories()

## Gameplay buff helpers — other scripts call these to apply buffs.
func get_cooking_multiplier() -> float:
	return Global.get_cooking_multiplier()

func get_tips_multiplier() -> float:
	return Global.get_tips_multiplier()

func get_patience_multiplier() -> float:
	return Global.get_patience_multiplier()
