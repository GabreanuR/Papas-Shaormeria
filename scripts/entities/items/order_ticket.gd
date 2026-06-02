extends Control

signal comanda_gata

@onready var container_ingrediente: VBoxContainer = $VBoxContainer 
@onready var label_numar: Label = $Number
@onready var iconita_suc: TextureRect = $IconitaSuc # <--- Nodul nou creat de noi!

const SMALL_SCALE := Vector2(0.35, 0.35)
const LARGE_SCALE := Vector2(1.3, 1.3)

var is_locked_large := false
var dimensiune_originala: Vector2
var id_client_proprietar: int = 0

var imagini_ingrediente := {
	"lipie": preload("res://assets/graphics/ingredients/lipie.png"), 
	"carne_pui": preload("res://assets/graphics/ingredients/carne_pui.png"),
	"carne_vita": preload("res://assets/graphics/ingredients/carne_vita.png"),
	"cartofi": preload("res://assets/graphics/ingredients/cartofi.png"),
	"castraveti_murati": preload("res://assets/graphics/ingredients/castraveti_murati.png"),
	"ceapa": preload("res://assets/graphics/ingredients/ceapa.png"),
	"chilli_flakes": preload("res://assets/graphics/ingredients/chilli_flakes.png"),
	"ketchup_dulce": preload("res://assets/graphics/ingredients/ketch.png"),
	"ketchup_picant": preload("res://assets/graphics/ingredients/spicy_ketch.png"),
	"maioneza": preload("res://assets/graphics/ingredients/mayo.png"),
	"maioneza_picanta": preload("res://assets/graphics/ingredients/spicy_mayo.png"),
	"maioneza_usturoi": preload("res://assets/graphics/ingredients/garlic.png"),
	"rosii": preload("res://assets/graphics/ingredients/rosii.png"),
	"salata": preload("res://assets/graphics/ingredients/salata.png"),
	"varza": preload("res://assets/graphics/ingredients/varza.png"),
	"falafel": preload("res://assets/graphics/ingredients/falafel.png"),
	"jalapenos": preload("res://assets/graphics/ingredients/jalapenos.png"),
	
	"suc_cola": preload("res://assets/graphics/ingredients/drink_1.png"),
	"suc_portocale": preload("res://assets/graphics/ingredients/drink_2.png"),
	"suc_lamaie": preload("res://assets/graphics/ingredients/drink_3.png")
}

func _ready() -> void:
	hide()
	pivot_offset = size / 2.0
	dimensiune_originala = size

func set_locked_large(locked: bool) -> void:
	is_locked_large = locked
	if is_locked_large:
		scale = LARGE_SCALE
	else:
		scale = SMALL_SCALE

func primeste_comanda(lista_ingrediente: Array, numar_client: int) -> void:
	id_client_proprietar = numar_client
	label_numar.text = str(numar_client).pad_zeros(2)
	show()
	
	await get_tree().create_timer(0.5).timeout
	
	for ingredient in lista_ingrediente:
		if imagini_ingrediente.has(ingredient):
			
			# VERIFICĂM DACĂ E SUC:
			if ingredient.begins_with("suc_"):
				iconita_suc.texture = imagini_ingrediente[ingredient]
				iconita_suc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				iconita_suc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				iconita_suc.show()
				await get_tree().create_timer(0.5).timeout
				
			else:
				# PENTRU RESTUL INGREDIENTELOR (Carne, Legume, Sosuri)
				var iconita_noua = TextureRect.new()
				iconita_noua.texture = imagini_ingrediente[ingredient]
				iconita_noua.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				iconita_noua.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				iconita_noua.custom_minimum_size = Vector2(48, 48)
				
				container_ingrediente.add_child(iconita_noua)
				container_ingrediente.move_child(iconita_noua, 0)
				await get_tree().create_timer(0.5).timeout
			
	comanda_gata.emit()

# Funcția nativă pentru când ÎNCEPI să tragi
func _get_drag_data(_at_position: Vector2) -> Variant:
	if is_locked_large and mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return null

	get_tree().call_group("drop_layer", "start_ticket_drag", self)

	var date_bilet = {
		"este_bilet_comanda": true,
		"nod_bilet": self,
		"numar_client": label_numar.text
	}

	# --- PREVIEW-UL MARE DE DRAG & DROP ---
	var preview_container = Control.new()
	
	var copie_vizuala = self.duplicate(0)
	copie_vizuala.size = dimensiune_originala
	copie_vizuala.scale = LARGE_SCALE # Cât timp îl ții în mână, e MARE
	copie_vizuala.show()
	
	# Aliniem imaginea exact în punctul în care ai înfipt mouse-ul!
	copie_vizuala.position = -_at_position * LARGE_SCALE	
	
	preview_container.add_child(copie_vizuala)
	set_drag_preview(preview_container)
	# --------------------------------------

	modulate.a = 0.4 # Biletul care rămâne fizic pe sfoară se face un pic transparent
	return date_bilet

# Funcția nativă pentru când LAȘI biletul din mână
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		modulate.a = 1.0 # Readucem biletul la opacitate normală
		get_tree().call_group("drop_layer", "stop_ticket_drag")
