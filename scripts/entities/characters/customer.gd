extends Node2D

var comanda_mea: Array = [] # O lăsăm goală la început
signal a_fost_apasat(ingrediente)
var a_dat_comanda: bool = false 
@onready var buton_comanda = $TextureButton
var rabdare_maxima: float = 100.0
var rabdare_curenta: float = 100.0
var scade_rabdare: bool = true # Se oprește când îi iei comanda

# Lista cu "meniul" de unde putem alege (fără lipie)
# ATENȚIE: Cuvintele de aici trebuie să fie scrise EXACT cum le vei scrie în dicționarul din bilet!
var ingrediente_disponibile: Array = [
	"ardei", "carne_pui", "carne_vita", "cartofi", 
	"castraveti_murati", "ceapa", "chilli_flakes", 
	"ketchup_dulce", "ketchup_picant", "maioneza", 
	"maioneza_picanta", "maioneza_usturoi", "rosii", 
	"salata", "varza", "jalapenos", "falafel"
]

# _ready se execută imediat ce apare clientul în scenă
func _ready():
	genereaza_comanda_random()
	pornește_animatie_buton()

# Adaugă această funcție nouă oriunde în script (de exemplu, la final):
func pornește_animatie_buton():
	var pozitie_initiala = buton_comanda.position
	
	# Creăm un Tween care se repetă la infinit (loop)
	var tween = create_tween().set_loops()
	
	# Îi spunem să urce 10 pixeli timp de 1 secundă, cu o mișcare lină (SINE)
	tween.tween_property(buton_comanda, "position:y", pozitie_initiala.y - 10, 1.0).set_trans(Tween.TRANS_SINE)
	# Apoi să coboare înapoi la poziția inițială
	tween.tween_property(buton_comanda, "position:y", pozitie_initiala.y, 1.0).set_trans(Tween.TRANS_SINE)

# Funcția noastră care creează logica comenzii
func genereaza_comanda_random():
	# 1. Începem cu lipia
	comanda_mea = ["lipie"]
	
	# 2. Alegem obligatoriu UN tip de carne
	var tipuri_carne = ["carne_pui", "carne_vita"]
	var carnea_aleasa = tipuri_carne.pick_random() # Alege pui sau vită
	comanda_mea.append(carnea_aleasa)
	
	# 3. Pregătim lista de ingrediente extra
	# Trebuie să scoatem cărnurile din lista de extra ca să nu le punem de două ori
	var extra_posibile = ingrediente_disponibile.duplicate()
	extra_posibile.erase("carne_pui")
	extra_posibile.erase("carne_vita")
	
	# 4. Alegem restul de ingrediente (între 2 și 7 extra)
	# (Avem deja 2 ingrediente, deci maxim 7 extra înseamnă total de 9)
	var numar_extra = randi_range(3, 7)
	extra_posibile.shuffle()
	
	for i in range(numar_extra):
		comanda_mea.append(extra_posibile[i])		

func _process(delta):
	# Dacă încă așteaptă să i se ia comanda, îi scade răbdarea
	if scade_rabdare and rabdare_curenta > 0:
		# Scadem vreo 2-3 puncte pe secundă. delta ne asigură că scade la fel de repede pe orice PC.
		rabdare_curenta -= 2.5 * delta 

# Modifică funcția de click ca să oprească scăderea răbdării:
func _on_texture_button_pressed():
	if a_dat_comanda == false:
		scade_rabdare = false # <--- Am adăugat asta: Clientul e fericit că l-ai băgat în seamă!
		a_fost_apasat.emit(comanda_mea)
		a_dat_comanda = true
