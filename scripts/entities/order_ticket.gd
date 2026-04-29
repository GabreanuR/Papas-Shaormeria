extends Control # Sau TextureRect, depinde ce tip de nod e radacina biletului tau

signal comanda_gata

# Legam codul de containerul tau vizual (ca sa stim unde sa bagam pozele)
@onready var container_ingrediente = $VBoxContainer 

@onready var label_numar = $Number

# Variabile pentru Drag & Drop
var e_pe_sfoara: bool = false
var se_trage: bool = false
var offset_mouse: Vector2 = Vector2.ZERO
var nod_carlig: Control = null
var sfoara_parent: BoxContainer = null

# 1. Dictionarul de traducere (Cuvant -> Poza)
# ATENTIE: Verifica ca caile sa fie exact ca in folderele tale!
var imagini_ingrediente = {
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

# 2. Funcția care va fi apelata cand clientul striga comanda
func primeste_comanda(lista_ingrediente: Array, numar_client: int):
	# Setăm textul biletului. 
	# Funcția pad_zeros(2) este un truc genial din Godot: transformă automat numărul 1 în "01", 2 în "02", dar pe 10 îl lasă "10".
	label_numar.text = str(numar_client).pad_zeros(2)
	
	# Biletul devine vizibil
	show()
	
	# CERINȚA 1: Pauză de 0.5 secunde înainte să apară primul ingredient
	await get_tree().create_timer(0.5).timeout
	
	for ingredient in lista_ingrediente:
		if imagini_ingrediente.has(ingredient):
			var iconita_noua = TextureRect.new()
			iconita_noua.texture = imagini_ingrediente[ingredient]
			iconita_noua.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			iconita_noua.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			
			# CERINȚA 2: Am mărit ingredientele de la 40 la 100. (Te poți juca cu cifrele astea!)
			iconita_noua.custom_minimum_size = Vector2(48, 48) 
			
			# Adăugăm ingredientul în container
			container_ingrediente.add_child(iconita_noua)
			
			# CERINȚA 3: Trucul pentru stivuire de jos în sus!
			# Mutăm noul ingredient adăugat la indexul 0 (adică deasupra celorlalte)
			container_ingrediente.move_child(iconita_noua, 0)
			
			# Pauza dintre ingrediente
			await get_tree().create_timer(0.5).timeout
			
	# Mai așteptăm o secundă ca jucătorul să apuce să citească comanda finală
	await get_tree().create_timer(1.5).timeout 
	# Ascundem biletul
	hide() 
	# Strigăm către scenă că am terminat!
	comanda_gata.emit()

# Această funcție citește click-urile direct pe bilet
func _gui_input(event):
	if not e_pe_sfoara:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Începem să tragem biletul
			se_trage = true
			offset_mouse = global_position - get_global_mouse_position()
			
			# Rupem biletul de pe cârlig
			if get_parent() == nod_carlig:
				# Folosim funcția reparent (nativă în Godot 4) pentru o mutare mai curată
				reparent(sfoara_parent.get_parent())
				nod_carlig.queue_free()
				
			global_position = get_global_mouse_position() + offset_mouse 
				
		elif not event.pressed: 
			# Dacă prinde semnalul normal de release, îl eliberăm
			elibereaza_bilet()

# Verificăm constant mișcarea
func _process(delta):
	if se_trage:
		global_position = get_global_mouse_position() + offset_mouse
		
		# TRUCUL SALVATOR: 
		# Dacă biletul crede că e tras, dar fizic mouse-ul nu mai e apăsat, îl forțăm să dea drumul!
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			elibereaza_bilet()

# Logica unde se așază biletul am pus-o separat ca să fie ordonată
func elibereaza_bilet():
	se_trage = false
	
	if global_position.y > 150: 
		scale = Vector2(1.2, 1.2) 
		position = Vector2(1202, 124) 
	else:
		scale = Vector2(0.4, 0.4) 
		global_position.y = 55
