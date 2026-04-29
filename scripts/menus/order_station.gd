extends Node2D

# Facem legăturile cu nodurile noastre
@onready var fundal_lobby = $LobbyFrame
@onready var fundal_comanda = $OrderFrame
@onready var bilet = $CanvasLayer/OrderTicket
@onready var buton_comanda = $Customer/TextureButton # Asigură-te că TextureButton e scris exact așa!
@onready var client = $Customer
@onready var poza_client = $Customer/Sprite2D
@onready var sfoara = $CanvasLayer/OrderRope
var poza_lobby = preload("res://assets/graphics/characters/papalouie.png")
var poza_close_up = preload("res://assets/graphics/characters/papalouie_zoomed.png")


# Funcția _ready se rulează automat o singură dată, fix când pornește scena
func _ready():
	# La început, vrem să vedem DOAR Lobby-ul
	fundal_lobby.show()
	fundal_comanda.hide()
	buton_comanda.show() # Butonul așteaptă să fie apăsat
	
	# Îi punem poza mică și îl așezăm în stânga, la coadă 
	poza_client.texture = poza_lobby
	client.position = Vector2(300, 313) # Te poți juca cu numerele astea (X, Y) până stă bine
	client.scale = Vector2(1, 1)


# Funcția legată de click-ul pe balonaș
func _on_customer_a_fost_apasat(comanda):
	# 1. Ascundem balonașul de comandă (și-a făcut treaba)
	buton_comanda.hide()
	
	# 2. SCHIMBĂM CADRUL (Tăietură de montaj directă)
	fundal_lobby.hide()
	fundal_comanda.show()
	
	# Starea 2: CLOSE-UP (Magia!)
	# Îi schimbăm poza cu aia cropped și îl teleportăm pe centru
	poza_client.texture = poza_close_up
	client.position = Vector2(800, 20) # 960 cu 540 este fix centrul ecranului
	client.scale = Vector2(1.3, 1.3)
	
	await get_tree().create_timer(0.5).timeout
	
	# Biletul pornește
	bilet.primeste_comanda(comanda)


# Această funcție se apelează automat când biletul strigă "comanda_gata"
func _on_order_ticket_comanda_gata():
	# 1. Cream o copie a biletului
	var bilet_mic = bilet.duplicate()
	bilet_mic.show()
	bilet_mic.position = Vector2(80, 5)

	
	# 2. TRUCUL: Creăm un "cârlig" invizibil care va sta pe sfoară
	var carlig = Control.new()
	# Îi spunem cârligului să rezerve exact 30% din lățimea/înălțimea biletului
	carlig.custom_minimum_size = bilet.size * 0.4
	
	# 3. Micșorăm biletul doar vizual (ingredientele nu se mai strivesc)
	bilet_mic.scale = Vector2(0.4, 0.4)
	bilet_mic.e_pe_sfoara = true
	bilet_mic.nod_carlig = carlig
	bilet_mic.sfoara_parent = sfoara
	
	# 4. Asamblăm: Punem biletul pe cârlig, și cârligul pe sfoară!
	carlig.add_child(bilet_mic)
	sfoara.add_child(carlig)
	
	# 5. SCHIMBĂM CADRUL ÎNAPOI
	fundal_comanda.hide()
	fundal_lobby.show()
	
	# 2. READUCEM CLIENTUL LA NORMAL
	poza_client.texture = poza_lobby # Îi dăm înapoi poza întreagă
	client.scale = Vector2(1, 1)     # Îl facem la loc mic
	client.position = Vector2(300, 313)
	
	# BUTONUL NU ÎL MAI APRINDEM! (Nu scriem buton_comanda.show())
	# Astfel, clientul va sta la coadă, dar fără buton, exact cum ai cerut.
