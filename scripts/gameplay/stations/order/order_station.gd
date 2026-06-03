extends Node2D

const CustomerHistoryScript = preload("res://scripts/ai/customer_history.gd")

@onready var fundal_lobby = $LobbyFrame
@onready var fundal_comanda = $OrderFrame
@onready var sfoara = $"../TopBar/HBoxContainer/TicketBackground/TicketZone"
@onready var label_scor = $LabelScor

const CustomerScene = preload("res://scenes/entities/characters/customer.tscn")
const OrderTicketScene = preload("res://scenes/entities/items/order_ticket.tscn")

var container_tava_evaluare: Node2D = null
var client_in_evaluare: Node = null # Ține minte exact cine e la tejghea acum
var semn_closed_afisat: bool = false
var clienti_serviti: int = 0
var total_clienti_zi: int = 0

var lista_clienti = [
	{ "lobby": preload("res://assets/graphics/characters/papalouie.png"), "zoom": preload("res://assets/graphics/characters/papalouie_zoomed.png") },
	{ "lobby": preload("res://assets/graphics/characters/wally.png"), "zoom": preload("res://assets/graphics/characters/wally_zoomed.png") },
	{ "lobby": preload("res://assets/graphics/characters/akari.png"), "zoom": preload("res://assets/graphics/characters/akari_zoomed.png") },
	{ "lobby": preload("res://assets/graphics/characters/chuck.png"), "zoom": preload("res://assets/graphics/characters/chuck_zoomed.png") },
	{ "lobby": preload("res://assets/graphics/characters/elle.png"), "zoom": preload("res://assets/graphics/characters/elle_zoomed.png") },
	{ "lobby": preload("res://assets/graphics/characters/kahuna.png"), "zoom": preload("res://assets/graphics/characters/kahuna_zoomed.png") },
	{ "lobby": preload("res://assets/graphics/characters/prudence.png"), "zoom": preload("res://assets/graphics/characters/prudence_zoomed.png") }
]

var profiluri_disponibile: Array = []
var coada_comenzi: Array = [] 
var zona_asteptare: Array = [] 

var timpi_spawn: Array[float] = [0.5, 30.0, 90.0, 150.0, 180.0]
var index_spawn: int = 0
var timp_scurs: float = 0.0
var contor_clienti_total: int = 1 
var offset_sfoara_urmator: float = 10.0 # Ajută la așezarea biletelor noi

func _ready():
	profiluri_disponibile = lista_clienti.duplicate()
	profiluri_disponibile.remove_at(0)
	profiluri_disponibile.shuffle()
	
	# SETĂM CONTORUL INIȚIAL
	total_clienti_zi = timpi_spawn.size()
	var gm = get_tree().current_scene
	if gm and gm.has_method("actualizeaza_text_clienti"):
		gm.actualizeaza_text_clienti(clienti_serviti, total_clienti_zi)
	
	fundal_lobby.show()
	fundal_comanda.hide()
	set_process(true)

func _process(delta: float):
	if index_spawn < timpi_spawn.size():
		timp_scurs += delta
		if timp_scurs >= timpi_spawn[index_spawn]:
			spawneaza_client_nou()
			index_spawn += 1
	else:
		# Dacă am terminat de spawnat toți clienții din array, punem semnul de închis!
		if not semn_closed_afisat:
			_afiseaza_semn_closed()
			semn_closed_afisat = true

func _afiseaza_semn_closed() -> void:
	var label_closed = Label.new()
	label_closed.text = "CLOSED"
	label_closed.add_theme_font_size_override("font_size", 48)
	label_closed.add_theme_color_override("font_color", Color(0.8, 0.1, 0.1)) # Roșu
	label_closed.add_theme_color_override("font_outline_color", Color(1, 1, 1))
	label_closed.add_theme_constant_override("outline_size", 8)
	
	fundal_lobby.add_child(label_closed)
	# Ajustează poziția în funcție de unde este ușa ta în imaginea Lobby-ului
	label_closed.position = Vector2(1600, 300) 
	label_closed.rotation_degrees = -15.0

func spawneaza_client_nou():
	if profiluri_disponibile.size() == 0:
		return
	
	var este_loyal := contor_clienti_total == 1
	var profil
	
	if este_loyal:
		profil = lista_clienti[0]
	else:
		profil = profiluri_disponibile.pop_back()
	
	var client_nou = CustomerScene.instantiate()
	
	client_nou.textura_lobby = profil["lobby"]
	client_nou.textura_zoom = profil["zoom"]
	client_nou.id_unic = contor_clienti_total
	client_nou.is_loyal_customer = este_loyal
	contor_clienti_total += 1
	
	client_nou.position = Vector2(2000, 313)
	client_nou.scale = Vector2(1, 1)
	add_child(client_nou)
	
	client_nou.a_fost_apasat.connect(_on_customer_a_fost_apasat.bind(client_nou))
	
	coada_comenzi.append(client_nou)
	actualizeaza_pozitii_coada()
	
	if fundal_comanda.visible:
		client_nou.hide()

# --- LOGICA DE COADĂ ---
func actualizeaza_pozitii_coada():
	for i in range(coada_comenzi.size()):
		var c = coada_comenzi[i]
		var target_x = 200 + (i * 300)
		c.z_index = 50 - i
		
		var tween_mers = create_tween()
		tween_mers.tween_property(c, "position:x", target_x, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		var tween_leganat = create_tween().set_loops()
		tween_leganat.tween_property(c, "rotation_degrees", 3.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween_leganat.tween_property(c, "rotation_degrees", -3.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		get_tree().create_timer(1.5).timeout.connect(func():
			if is_instance_valid(c):
				tween_leganat.kill()
				create_tween().tween_property(c, "rotation_degrees", 0.0, 0.1)
		)
		
		var buton = c.get_node("TextureButton")
		if i == 0:
			buton.show() 
		else:
			buton.hide()
			
			
# --- NOU: LOGICA REPARATĂ PENTRU ZONA DE AȘTEPTARE ---
func actualizeaza_pozitii_asteptare():
	for i in range(zona_asteptare.size()):
		var c = zona_asteptare[i]
		if not is_instance_valid(c): continue
		
		# Folosim indexul 'i' (0, 1, 2...) în loc de .size()!
		# Primul client din zona de așteptare va sta la X=200, următorul la X=450, etc.
		var target_x = 200 + (i * 250)
		
		# Z-index-ul scade spre spate ca să se randeze corect în spațiu 3D virtual
		c.z_index = 20 - i
		
		var tween = create_tween()
		tween.tween_property(c, "position", Vector2(target_x, 250), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		

# --- CÂND APĂSĂM PE BALONAȘUL UNUI CLIENT NOU ---
func _on_customer_a_fost_apasat(comanda, clientul_apasat):
	# Curățenie bilet anterior (dacă e cazul)
	for copil in fundal_comanda.get_children():
		if copil.has_method("set_locked_large"):
			_pune_bilet_pe_sfoara(copil)

	var gm = get_tree().current_scene
	if gm and gm.has_method("seteaza_stare_butoane_statii"):
		gm.seteaza_stare_butoane_statii(false)

	clientul_apasat.get_node("TextureButton").hide()
	coada_comenzi.erase(clientul_apasat)
	zona_asteptare.append(clientul_apasat)
	
	# --- FIX WAITING SCORE: TRECEM CLIENTUL PE RĂBDARE LENTĂ! ---
	if "rata_curenta" in clientul_apasat and "rata_scadere_gatit" in clientul_apasat:
		clientul_apasat.rata_curenta = clientul_apasat.rata_scadere_gatit
	
	actualizeaza_pozitii_coada()
	
	for c in coada_comenzi: c.hide()
	for c in zona_asteptare:
		if c != clientul_apasat: c.hide()
	
	fundal_lobby.hide()
	fundal_comanda.show()
	
	if clientul_apasat.has_method("seteaza_sprite_comanda"):
		clientul_apasat.seteaza_sprite_comanda()
	else:
		clientul_apasat.get_node("Sprite2D").texture = clientul_apasat.textura_zoom
	clientul_apasat.position = Vector2(800, 55) 
	clientul_apasat.scale = Vector2(1.3, 1.3)
	clientul_apasat.z_index = 100 
	
	var tichet_nou = OrderTicketScene.instantiate()
	fundal_comanda.add_child(tichet_nou)
	tichet_nou.position = Vector2(1300, 200) 
	tichet_nou.set_locked_large(true) 
	
	await get_tree().create_timer(0.5).timeout
	
	# FIX IMPORTANT: ÎNTÂI conectăm semnalul, APOI îi dăm comanda!
	tichet_nou.comanda_gata.connect(_on_order_ticket_comanda_gata.bind(tichet_nou, clientul_apasat))
	tichet_nou.primeste_comanda(comanda, clientul_apasat.id_unic)
	
func _on_order_ticket_comanda_gata(tichet_rezolvat, clientul_apasat):
	var gm = get_tree().current_scene
	if gm and gm.has_method("seteaza_stare_butoane_statii"):
		gm.seteaza_stare_butoane_statii(true)
	
	_pune_bilet_pe_sfoara(tichet_rezolvat)
	
	fundal_comanda.hide()
	fundal_lobby.show()
	
	for c in coada_comenzi: c.show()
	for c in zona_asteptare: c.show()
	
	if clientul_apasat.has_method("seteaza_sprite_lobby"):
		clientul_apasat.seteaza_sprite_lobby()
	else:
		clientul_apasat.get_node("Sprite2D").texture = clientul_apasat.textura_lobby

	clientul_apasat.scale = Vector2(0.85, 0.85) 
	
	# REPARAT: Nu mai calculăm o poziție fixă aici, ci chemăm funcția dinamică!
	actualizeaza_pozitii_asteptare()
	
	
# --- FORȚĂM MICȘORAREA BILETULUI ---
func _pune_bilet_pe_sfoara(tichet_rezolvat):
	# Dacă e deja pe sfoară, îl lăsăm în pace
	if tichet_rezolvat.get_parent() != fundal_comanda:
		return
		
	# Aici lăsăm codul tău original să facă magia de micșorare!
	tichet_rezolvat.set_locked_large(false)
	tichet_rezolvat.get_parent().remove_child(tichet_rezolvat)
	
	var carlig = Control.new()
	carlig.custom_minimum_size = Vector2(55, 65) 
	
	# Permitem mouse-ului să tragă de el
	carlig.mouse_filter = Control.MOUSE_FILTER_PASS 
	carlig.gui_input.connect(_on_carlig_drag.bind(carlig))
	carlig.set_meta("is_dragging", false)
	
	tichet_rezolvat.tree_exited.connect(carlig.queue_free)
	
	carlig.add_child(tichet_rezolvat)
	
	# FOLOSIM VARIABILA TA ORIGINALĂ
	sfoara.add_child(carlig)
	
	# Poziția în cârlig și pe sfoară
	tichet_rezolvat.position = Vector2(25, 30)
	carlig.position = Vector2(offset_sfoara_urmator, 0)
	offset_sfoara_urmator += 80.0 # Îi dăm mai mult spațiu între ele (80px)

# --- DRAG & DROP ADAPTAT LA NOUA LĂȚIME ---
func _on_carlig_drag(event: InputEvent, carlig: Control):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			carlig.set_meta("is_dragging", true)
			carlig.z_index = 100 # Îl aducem în față
			# Îl punem ultimul în listă ca să se randeze peste celelalte bilete
			carlig.get_parent().move_child(carlig, -1)
		else:
			carlig.set_meta("is_dragging", false)
			carlig.z_index = 0
			
	elif event is InputEventMouseMotion and carlig.get_meta("is_dragging"):
		# Mișcăm biletul la stânga și la dreapta o dată cu mouse-ul
		carlig.position.x += event.relative.x
		
		# IGNORĂM lățimea containerului și îi dăm voie fixă să fie tras pe ecran (0 - 1500 pixeli)
		carlig.position.x = clamp(carlig.position.x, 0, 1500)
# -------------------------------------------------------------

	# --- SISTEMUL DE LIVRARE ȘI EVALUARE ---
# Această funcție va fi apelată de GameplayMaster când apeși "Send" la Wrapping Station
func aduce_client_pentru_evaluare(id_cautat: int) -> void:
	var client_gasit = null
	
	for c in zona_asteptare:
		if c.id_unic == id_cautat:
			client_gasit = c
			break
			
	if client_gasit == null:
		print("Eroare: Nu am găsit clientul cu ID ", id_cautat, " în sala de așteptare!")
		return
		
	# LOGICĂ NOUĂ: Îl salvăm aici ca să îl putem șterge din joc după cele 10 secunde de note!
	client_in_evaluare = client_gasit
	zona_asteptare.erase(client_gasit)
	
	for c in coada_comenzi: c.hide()
	for c in zona_asteptare: c.hide()
	
	fundal_lobby.hide()
	fundal_comanda.show()
	
	if client_gasit.has_method("seteaza_sprite_comanda"):
		client_gasit.seteaza_sprite_comanda()
	else:
		client_gasit.get_node("Sprite2D").texture = client_gasit.textura_zoom
	client_gasit.position = Vector2(800, 55) 
	client_gasit.scale = Vector2(1.3, 1.3)
	client_gasit.z_index = 100
	

func obtine_comanda_client(id_cautat: int) -> Array:
	# Căutăm în sala de așteptare
	for c in zona_asteptare:
		if c.id_unic == id_cautat:
			return c.comanda_mea
			
	# Căutăm și în coadă (just in case)
	for c in coada_comenzi:
		if c.id_unic == id_cautat:
			return c.comanda_mea
			
	return []

# --- SISTEMUL DE LIVRARE ȘI EVALUARE (REPARAT COMPLET) ---

func pregateste_tejgheaua_pentru_evaluare() -> void:
	# Ne asigurăm că suntem pe cadrul de close-up
	fundal_lobby.hide()
	fundal_comanda.show()

func arata_evaluare_finala(nota: int, textura_lipie: Texture2D, textura_suc: Texture2D) -> void:
	var gm = get_tree().current_scene
	if gm and gm.has_method("seteaza_stare_butoane_statii"):
		gm.seteaza_stare_butoane_statii(false)
	
	if container_tava_evaluare != null and is_instance_valid(container_tava_evaluare):
		container_tava_evaluare.queue_free()
		
	container_tava_evaluare = Node2D.new()
	fundal_comanda.add_child(container_tava_evaluare)
	
	container_tava_evaluare.z_index = 101 # Un pic peste client
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

	# --- 4. EXTRACȚIE SCORURI ȘI CALCUL BACȘIȘ ---
	var s_waiting := 0
	var s_cutting := 0
	var s_assembly := 0
	var s_wrapping := 0
	var medie_generala := 0
	var bacsis_primit := 0.0 
	
	if gm and "completed_pitas" in gm and gm.completed_pitas.size() > 0:
		var ultima_shaorma = gm.completed_pitas.back()
		var s = ultima_shaorma.get("scores", {})
		
		s_waiting = s.get("waiting", 0)
		s_cutting = s.get("cutting", 0)
		s_assembly = s.get("assembly", 0)
		s_wrapping = s.get("wrapping", 0)
		
		medie_generala = floor((s_waiting + s_cutting + s_assembly + s_wrapping) / 4.0)
		
		if medie_generala >= 50:
			bacsis_primit = (medie_generala / 100.0) * 5.00
			
		if gm.has_method("adauga_bacsis"):
			gm.adauga_bacsis(bacsis_primit)

	# --- 5. AFIȘARE PANOU SCORURI ---
	if label_scor != null:
		label_scor.text = (
			"Waiting Score: " + str(s_waiting) + "%\n" +
			"Cutting Score: " + str(s_cutting) + "%\n" +
			"Assembly Score: " + str(s_assembly) + "%\n" +
			"Wrapping Score: " + str(s_wrapping) + "%\n" +
			"---------------------\n" +
			"TOTAL: " + str(medie_generala) + "%\n" +
			"Tip: +$ %.2f" % bacsis_primit
		)
		
		label_scor.reset_size()
		label_scor.show()
		label_scor.z_index = 200 # Să fie clar deasupra
		label_scor.global_position = Vector2(300 - (label_scor.size.x / 2.0), 200)
		
	# --- 6. FADE IN REFRESHING ---
	var ecran_negru = ColorRect.new()
	ecran_negru.color = Color(0, 0, 0, 1) 
	ecran_negru.set_anchors_preset(Control.PRESET_FULL_RECT) 
	ecran_negru.size = Vector2(1920, 1080)
	ecran_negru.z_index = 1000
	add_child(ecran_negru)
	
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(ecran_negru, "color:a", 0.0, 0.5) 
	fade_in_tween.finished.connect(ecran_negru.queue_free) 
	
	# --- 7. MAGIA CELOR 7 SECUNDE ---
	if client_in_evaluare != null and is_instance_valid(client_in_evaluare):
		if client_in_evaluare.is_loyal_customer:
			CustomerHistoryScript.save_interaction({
				"customer_id": client_in_evaluare.id_unic,
				"order": client_in_evaluare.comanda_mea,
				"score": medie_generala,
				"was_wrong": medie_generala < 70,
				"waiting": s_waiting,
				"cutting": s_cutting,
				"assembly": s_assembly,
				"wrapping": s_wrapping,
				"timestamp": Time.get_datetime_string_from_system()
			})
	await get_tree().create_timer(7.0).timeout
	
	# --- 8. CURĂȚENIA ȘI REVENIREA REUȘITĂ LA LOBBY ---
	if label_scor != null:
		label_scor.hide()
	if container_tava_evaluare != null and is_instance_valid(container_tava_evaluare):
		container_tava_evaluare.queue_free()
		
	# Clientul servit își ia mâncarea și este șters definitiv
	if client_in_evaluare != null and is_instance_valid(client_in_evaluare):
		client_in_evaluare.queue_free()
		client_in_evaluare = null
		
	# Închidem close-up-ul și aprindem Lobby-ul normal
	fundal_comanda.hide()
	fundal_lobby.show()
	
	# REPARAT COMPLET: Recalculăm pozițiile pentru clienții rămași în așteptare!
	# Clientul 2, care era pe poziția a doua, va trece automat pe poziția 1 (X=200)!
	actualizeaza_pozitii_asteptare()
	
	# Afișăm din nou toți ceilalți clienți rămași în restaurant
	for c in coada_comenzi: c.show()
	for c in zona_asteptare: c.show()
	
	# --- NOU: DEBLOCĂM BUTOANELE PENTRU URMĂTOAREA COMANDĂ ---
	if gm and gm.has_method("seteaza_stare_butoane_statii"):
		gm.seteaza_stare_butoane_statii(true)
	
	# --- NOU: LOGICA DE END OF DAY ---
	clienti_serviti += 1
	
	if gm and gm.has_method("actualizeaza_text_clienti"):
		gm.actualizeaza_text_clienti(clienti_serviti, total_clienti_zi)
		
	# Dacă am servit toți clienții planificați pentru azi, trecem direct la ecranul de final!
	if clienti_serviti >= total_clienti_zi:
		if gm and gm.has_method("_on_day_ended"):
			gm._on_day_ended()
