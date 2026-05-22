extends Control

signal comanda_gata

@onready var container_ingrediente: VBoxContainer = $VBoxContainer 
@onready var label_numar: Label = $Number

const SMALL_SCALE := Vector2(0.25, 0.25)
const LARGE_SCALE := Vector2(1.0, 1.0)

var is_locked_large := false
var _zoom_tween: Tween

# Dictionarul de traducere (Cuvant -> Poza) rămâne neatins!
var imagini_ingrediente := {
	"lipie": preload("res://assets/graphics/ingredients/lipie.png"), 
	"carne_pui": preload("res://assets/graphics/ingredients/carne_pui.png"),
	"carne_vita": preload("res://assets/graphics/ingredients/carne_vita.png"),
	"cartofi": preload("res://assets/graphics/ingredients/cartofi.png"),
	"castraveti_murati": preload("res://assets/graphics/ingredients/castraveti_murati.png"),
	"ceapa": preload("res://assets/graphics/ingredients/ceapa.png"),
	"chilli_flakes": preload("res://assets/graphics/ingredients/chilli_flakes.png"),
	"ketchup_dulce": preload("res://assets/graphics/ingredients/ketchup_dulce.png"),
	"ketchup_picant": preload("res://assets/graphics/ingredients/ketchup_picant.png"),
	"maioneza": preload("res://assets/graphics/ingredients/maioneza.png"),
	"maioneza_picanta": preload("res://assets/graphics/ingredients/maioneza_picanta.png"),
	"maioneza_usturoi": preload("res://assets/graphics/ingredients/maioneza_usturoi.png"),
	"rosii": preload("res://assets/graphics/ingredients/rosii.png"),
	"salata": preload("res://assets/graphics/ingredients/salata.png"),
	"varza": preload("res://assets/graphics/ingredients/varza.png"),
	"falafel": preload("res://assets/graphics/ingredients/falafel.png"),
	"jalapenos": preload("res://assets/graphics/ingredients/jalapenos.png")
}

func _ready() -> void:
	hide()
	
	# Setăm punctul de pivot în centru ca să se mărească frumos din mijloc!
	pivot_offset = size / 2.0
	
	mouse_entered.connect(_on_mouse_hover_start)
	mouse_exited.connect(_on_mouse_hover_end)

# ==========================================
# GESTIONAREA MĂRIMII ȘI A HOVER-ULUI
# ==========================================

func set_locked_large(locked: bool) -> void:
	is_locked_large = locked
	if is_locked_large:
		scale = LARGE_SCALE
	else:
		scale = SMALL_SCALE

func _on_mouse_hover_start() -> void:
	if is_locked_large: return
	
	z_index = 50 
	_animate_size(LARGE_SCALE)

func _on_mouse_hover_end() -> void:
	if is_locked_large: return
	
	z_index = 0
	_animate_size(SMALL_SCALE)

func _animate_size(target_scale: Vector2) -> void:
	if _zoom_tween and _zoom_tween.is_valid():
		_zoom_tween.kill()
		
	_zoom_tween = create_tween()
	_zoom_tween.tween_property(self, "scale", target_scale, 0.15).set_ease(Tween.EASE_OUT)

# ==========================================
# POPULARE ȘI DRAG & DROP
# ==========================================

func primeste_comanda(lista_ingrediente: Array, numar_client: int) -> void:
	label_numar.text = str(numar_client).pad_zeros(2)
	show()
	
	await get_tree().create_timer(0.5).timeout
	
	for ingredient in lista_ingrediente:
		if imagini_ingrediente.has(ingredient):
			var iconita_noua = TextureRect.new()
			iconita_noua.texture = imagini_ingrediente[ingredient]
			iconita_noua.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			iconita_noua.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			
			# REVENIM la dimensiunea fixă, fără să le forțăm să se întindă vertical!
			iconita_noua.custom_minimum_size = Vector2(48, 48)
			
			container_ingrediente.add_child(iconita_noua)
			container_ingrediente.move_child(iconita_noua, 0)
			
			await get_tree().create_timer(0.5).timeout
			
	comanda_gata.emit()

func _get_drag_data(_at_position: Vector2) -> Variant:
	var date_bilet = {
		"este_bilet_comanda": true,
		"nod_bilet": self,
		"numar_client": label_numar.text
	}
	
	var drag_preview = Control.new()
	var clona_bilet = self.duplicate()
	
	# Forțăm clona să fie mare cât e în mână!
	clona_bilet.scale = LARGE_SCALE 
	clona_bilet.position = -(clona_bilet.size * clona_bilet.scale) / 2.0 
	
	drag_preview.add_child(clona_bilet)
	set_drag_preview(drag_preview)
	
	modulate.a = 0.4
	return date_bilet

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		modulate.a = 1.0
		_on_mouse_hover_end()
