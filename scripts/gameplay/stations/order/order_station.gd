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
@onready var label_scor = $LabelScor
var container_tava_evaluare: Node2D = null

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
	# BLOCĂM BUTOANELE DE JOS!
	var gm = get_tree().current_scene
	if gm and gm.has_method("seteaza_stare_butoane_statii"):
		gm.seteaza_stare_butoane_statii(false)

	# 1. Ascundem balonașul de comandă (și-a făcut treaba)
	buton_comanda.hide()
	
	# 2. SCHIMBĂM CADRUL (Tăietură de montaj directă)
	fundal_lobby.hide()
	fundal_comanda.show()
	
	# Starea 2: CLOSE-UP (Magia!)
	poza_client.texture = client_curent_zoom
	client.position = Vector2(800, 55) 
	client.scale = Vector2(1.3, 1.3)
	
	# Creăm biletul vizual și îl punem pe tejghea
	var tichet_nou = OrderTicketScene.instantiate()
	fundal_comanda.add_child(tichet_nou)
	tichet_nou.position = Vector2(1300, 200) 
	tichet_nou.set_locked_large(true) 
	
	await get_tree().create_timer(0.5).timeout
	
	# Trimitem atât comanda, cât și numărul curent!
	tichet_nou.primeste_comanda(comanda, contor_clienti)
	
	# Ne legăm de semnal și transmitem și referința biletului
	tichet_nou.comanda_gata.connect(_on_order_ticket_comanda_gata.bind(tichet_nou))
	
	# După ce am dat comanda biletului, creștem contorul pentru următorul client
	contor_clienti += 1

# Această funcție se apelează automat când biletul strigă "comanda_gata"
func _on_order_ticket_comanda_gata(tichet_rezolvat):
	# DEBLOCĂM BUTOANELE!
	var gm = get_tree().current_scene
	if gm and gm.has_method("seteaza_stare_butoane_statii"):
		gm.seteaza_stare_butoane_statii(true)
	
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
	# REFRESH LA CLIENT (Răbdare 100%, comandă nouă, viteză de coadă!)
	if client != null and client.has_method("pregateste_client_nou"):
		client.pregateste_client_nou()

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

func pregateste_tejgheaua_pentru_evaluare() -> void:
	# 1. Schimbăm cadrul pe tejghea (de aproape)
	fundal_lobby.hide()
	fundal_comanda.show()
	
	# 2. Ne asigurăm că clientul este în starea de zoom, la locul lui
	if poza_client != null and client_curent_zoom != null:
		poza_client.texture = client_curent_zoom
		client.position = Vector2(800, 55)
		client.scale = Vector2(1.3, 1.3)

func arata_evaluare_finala(nota: int, textura_lipie: Texture2D, textura_suc: Texture2D) -> void:
	if container_tava_evaluare != null and is_instance_valid(container_tava_evaluare):
		container_tava_evaluare.queue_free()
		
	container_tava_evaluare = Node2D.new()
	fundal_comanda.add_child(container_tava_evaluare)
	
	container_tava_evaluare.z_index = 100
	container_tava_evaluare.position = Vector2(960, 800)
	
	# --- 1. POZA TAVA ---
	var sprite_tava = Sprite2D.new()
	sprite_tava.texture = preload("res://assets/graphics/wrapping_station/tray.png")
	sprite_tava.scale = Vector2(0.35, 0.35) 
	container_tava_evaluare.add_child(sprite_tava)
	
	# --- 2. SUCUL ---
	if textura_suc != null:
		var sprite_suc = Sprite2D.new()
		sprite_suc.texture = textura_suc
		sprite_suc.position = Vector2(100, -20) 
		sprite_suc.scale = Vector2(0.3, 0.3) 
		container_tava_evaluare.add_child(sprite_suc)
		
	# --- 3. LIPIA ---
	if textura_lipie != null:
		var sprite_lipie = Sprite2D.new()
		sprite_lipie.texture = textura_lipie
		sprite_lipie.position = Vector2(-100, -20) 
		sprite_lipie.scale = Vector2(0.3, 0.3)
		container_tava_evaluare.add_child(sprite_lipie)

	# --- 4. EXTRACTIE SCORURI IN PROCENTE ȘI MEDIE ---
	var gm = get_tree().current_scene
	var s_waiting := 0
	var s_cutting := 0
	var s_assembly := 0
	var s_wrapping := 0
	var medie_generala := 0
	var bacsis_primit := 0.0 # <--- NOU
	
	if gm and "completed_pitas" in gm and gm.completed_pitas.size() > 0:
		var ultima_shaorma = gm.completed_pitas.back()
		var s = ultima_shaorma.get("scores", {})
		
		s_waiting = s.get("waiting", 0)
		s_cutting = s.get("cutting", 0)
		s_assembly = s.get("assembly", 0)
		s_wrapping = s.get("wrapping", 0)
		
		medie_generala = floor((s_waiting + s_cutting + s_assembly + s_wrapping) / 4.0)
		
		# --- CALCUL BACȘIȘ ---
		# Bacșiș maxim: 5.00$. Dacă media e < 50%, primești 0$.
		if medie_generala >= 50:
			bacsis_primit = (medie_generala / 100.0) * 5.00
			
		# Trimitem banii la master să-i pună în seif și să schimbe textul din TopBar!
		if gm.has_method("adauga_bacsis"):
			gm.adauga_bacsis(bacsis_primit)

	# --- 5. AFIȘARE TEXT MULTILINE (Acum include și bacșișul) ---
	if label_scor != null:
		label_scor.text = (
			"Waiting Score: " + str(s_waiting) + "%\n" +
			"Cutting Score: " + str(s_cutting) + "%\n" +
			"Assembly Score: " + str(s_assembly) + "%\n" +
			"Wrapping Score: " + str(s_wrapping) + "%\n" +
			"---------------------\n" +
			"TOTAL: " + str(medie_generala) + "%\n" +
			"Tip: +$ %.2f" % bacsis_primit # <--- Arată bacșișul cu 2 zecimale!
		)
		
		label_scor.reset_size()
		label_scor.show()
		label_scor.global_position = Vector2(300 - (label_scor.size.x / 2.0), 200)
		
	# --- 6. FADE IN DIN NEGRU ---
	var ecran_negru = ColorRect.new()
	ecran_negru.color = Color(0, 0, 0, 1) 
	ecran_negru.set_anchors_preset(Control.PRESET_FULL_RECT) 
	ecran_negru.size = Vector2(1920, 1080)
	ecran_negru.z_index = 1000
	add_child(ecran_negru)
	
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(ecran_negru, "color:a", 0.0, 0.5) 
	fade_in_tween.finished.connect(ecran_negru.queue_free) 
	
	# --- 7. AȘTEPTĂM 3 SECUNDE ȘI CURĂȚĂM TAVA ---
	await get_tree().create_timer(10.0).timeout
	
	if label_scor != null:
		label_scor.hide()
	container_tava_evaluare.queue_free()
