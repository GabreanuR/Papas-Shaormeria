extends Node2D

# Facem legăturile cu nodurile noastre
@onready var fundal_lobby = $LobbyFrame
@onready var fundal_comanda = $OrderFrame
@onready var buton_comanda = $Customer/TextureButton # Asigură-te că TextureButton e scris exact așa!
@onready var client = $Customer
@onready var poza_client = $Customer/Sprite2D
const OrderTicketScene = preload("res://scenes/entities/items/order_ticket.tscn")
@onready var sfoara = $"../TopBar/HBoxContainer/TicketBackground/TicketZone"
var contor_clienti: int = 1

# 2. ADAUGĂ în locul lor această listă de "Profiluri" (Dicționare):
var lista_clienti = [
	{
		"lobby": preload("res://assets/graphics/characters/papalouie.png"),
		"zoom": preload("res://assets/graphics/characters/papalouie_zoomed.png")
	}
	 ,{
	 	"lobby": preload("res://assets/graphics/characters/wally.png"),
	 	"zoom": preload("res://assets/graphics/characters/wally_zoomed.png")
	 }
	,{
	 	"lobby": preload("res://assets/graphics/characters/akari.png"),
	 	"zoom": preload("res://assets/graphics/characters/akari_zoomed.png")
	 }
	,{
	 	"lobby": preload("res://assets/graphics/characters/chuck.png"),
	 	"zoom": preload("res://assets/graphics/characters/chuck_zoomed.png")
	 }
	,{
	 	"lobby": preload("res://assets/graphics/characters/elle.png"),
	 	"zoom": preload("res://assets/graphics/characters/elle_zoomed.png")
	 }
	,{
	 	"lobby": preload("res://assets/graphics/characters/kahuna.png"),
	 	"zoom": preload("res://assets/graphics/characters/kahuna_zoomed.png")
	 }
	,{
	 	"lobby": preload("res://assets/graphics/characters/prudence.png"),
	 	"zoom": preload("res://assets/graphics/characters/prudence_zoomed.png")
	 }
]

# 3. Adaugă două variabile noi care vor ține minte clientul ales la momentul respectiv:
var client_curent_lobby: Texture2D
var client_curent_zoom: Texture2D

# Funcția _ready se rulează automat o singură dată, fix când pornește scena
func _ready():
	var profil_random = lista_clienti.pick_random()
	client_curent_lobby = profil_random["lobby"]
	client_curent_zoom = profil_random["zoom"]
	
	# La început, vrem să vedem DOAR Lobby-ul
	fundal_lobby.show()
	fundal_comanda.hide()
	
	# Îi punem poza mică și îl așezăm în stânga, la coadă 
	poza_client.texture = client_curent_lobby
	client.scale = Vector2(1, 1)
	adu_client_la_tejghea()

# Funcția legată de click-ul pe balonaș
func _on_customer_a_fost_apasat(comanda):
	# 1. Ascundem balonașul de comandă (și-a făcut treaba)
	buton_comanda.hide()
	
	# 2. SCHIMBĂM CADRUL (Tăietură de montaj directă)
	fundal_lobby.hide()
	fundal_comanda.show()
	
	# Starea 2: CLOSE-UP (Magia!)
	# Îi schimbăm poza cu aia cropped și îl teleportăm pe centru
	poza_client.texture = client_curent_zoom
	client.position = Vector2(800, 55) # 960 cu 540 este fix centrul ecranului
	client.scale = Vector2(1.3, 1.3)
	
	# Creăm biletul vizual și îl punem pe tejghea (în fundal_comanda)
	var tichet_nou = OrderTicketScene.instantiate()
	fundal_comanda.add_child(tichet_nou)
	tichet_nou.position = Vector2(150, 150) # Coordonate de probă pentru tejghea
	tichet_nou.set_locked_large(true) # Îl ținem mare pe tejghea
	
	await get_tree().create_timer(0.5).timeout
	
	# Trimitem atât comanda, cât și numărul curent!
	tichet_nou.primeste_comanda(comanda, contor_clienti)
	
	# Ne legăm de semnal și transmitem și referința biletului
	tichet_nou.comanda_gata.connect(_on_order_ticket_comanda_gata.bind(tichet_nou))
	
	# După ce am dat comanda biletului, creștem contorul pentru următorul client
	contor_clienti += 1

# Această funcție se apelează automat când biletul strigă "comanda_gata"
func _on_order_ticket_comanda_gata(tichet_rezolvat):
	# 1. Deblocăm biletul ca să devină mic (scale = 0.4)
	tichet_rezolvat.set_locked_large(false)
	tichet_rezolvat.get_parent().remove_child(tichet_rezolvat)
	
	# 2. Creăm un "cârlig" invizibil care va sta pe șina HBoxContainer
	var carlig = Control.new()
	carlig.mouse_filter = Control.MOUSE_FILTER_IGNORE # CRITIC: Ca să nu blocheze click-urile (Drag & Drop)
	
	# Cârligul dictează spațiul ocupat pe șină! (Ajustat pentru scale = 0.25)
	carlig.custom_minimum_size = Vector2(45, 65) 
	
	# 3. Leagă viața cârligului de viața biletului: când biletul e preluat, ștergem și cârligul.
	tichet_rezolvat.tree_exited.connect(carlig.queue_free)
	
	# 4. Punem biletul în cârlig, și cârligul pe șină
	carlig.add_child(tichet_rezolvat)
	sfoara.add_child(carlig)
	
	# Ca să arate centrat în cârlig
	tichet_rezolvat.position = carlig.custom_minimum_size / 2.0
	
	# 5. SCHIMBĂM CADRUL ÎNAPOI
	fundal_comanda.hide()
	fundal_lobby.show()
	
	# 4. READUCEM CLIENTUL LA NORMAL
	poza_client.texture = client_curent_lobby # Îi dăm înapoi poza întreagă
	client.scale = Vector2(1, 1)     # Îl facem la loc mic
	client.position = Vector2(200, 313)
	
	# BUTONUL NU ÎL MAI APRINDEM! (Nu scriem buton_comanda.show())
	# Astfel, clientul va sta la coadă, dar fără buton, exact cum ai cerut.

func adu_client_la_tejghea():
	# 1. Îl ascundem în afara ecranului, în DREAPTA (ex: X = 1200)
	client.position = Vector2(2000, 313)
	client.rotation_degrees = 0.0 # Îl resetăm să stea drept la început
	buton_comanda.hide()
	
	# 2. TWEEN-UL PENTRU DEPLASARE (Glisarea principală)
	var tween_mers = create_tween()
	# Merge de la 1200 înapoi la 300 (la stânga), cu încetinire la final
	tween_mers.tween_property(client, "position:x", 200, 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 3. TWEEN-UL PENTRU LEGĂNAT (Mult mai fin)
	var tween_leganat = create_tween().set_loops()
	
	# Pășește finuț stânga-dreapta
	tween_leganat.tween_property(client, "rotation_degrees", 3.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_leganat.tween_property(client, "rotation_degrees", -3.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# 4. Așteptăm ca deplasarea pe X să se termine
	await tween_mers.finished
	
	# 5. Oprim legănatul
	tween_leganat.kill()
	
	# 6. Îl îndreptăm finuț înapoi la 0 grade
	var tween_stop = create_tween()
	tween_stop.tween_property(client, "rotation_degrees", 0.0, 0.1).set_trans(Tween.TRANS_SINE)
	
	# 7. Afișăm balonașul
	buton_comanda.show()
