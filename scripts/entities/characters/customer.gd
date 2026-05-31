extends Node2D

var comanda_mea: Array = []
signal a_fost_apasat(ingrediente)
signal patience_expired
var a_dat_comanda: bool = false 
@onready var buton_comanda = $TextureButton

@export var rabdare_maxima: float = 100.0
@export var rata_scadere_coada: float = 1.0 # Scade REPEDE la coadă (ajunge la 0 în 40 sec)
@export var rata_scadere_gatit: float = 0.01 # Scade ÎNCET cât gătești (ajunge la 0 în 3+ minute)

var rabdare_curenta: float = rabdare_maxima
var scade_rabdare: bool = true 
var rata_curenta: float = rata_scadere_coada # Ritmul care se aplică acum

# Am împărțit ingredientele în categorii clare!
var legume_disponibile: Array = [
	"ardei", "cartofi", "castraveti_murati", "ceapa", 
	"chilli_flakes", "rosii", "salata", "varza", "jalapenos", "falafel"
]

var sosuri_disponibile: Array = [
	"ketchup_dulce", "ketchup_picant", "maioneza", 
	"maioneza_picanta", "maioneza_usturoi"
]

# Numele trebuie să fie exact ca în dicționarul din order_ticket.gd!
var sucuri_disponibile: Array = [
	"suc_cola", "suc_portocale", "suc_lamaie"
]

# Funcția nouă care respectă ordinea logică a stațiilor
func genereaza_comanda_random():
	comanda_mea = ["lipie"]
	
	# 1. CARNEA (O singură opțiune)
	var tipuri_carne = ["carne_pui", "carne_vita"]
	comanda_mea.append(tipuri_carne.pick_random())
	
	# 2. LEGUMELE (Alegem 2, 3 sau 4 legume la întâmplare)
	var legume_amestecate = legume_disponibile.duplicate()
	legume_amestecate.shuffle() # Le amestecăm ca într-un pachet de cărți
	var numar_legume = randi_range(2, 4)
	for i in range(numar_legume):
		comanda_mea.append(legume_amestecate[i])
		
	# 3. SOSURILE (Alegem 1 sau 2 sosuri la întâmplare, DUPĂ legume)
	var sosuri_amestecate = sosuri_disponibile.duplicate()
	sosuri_amestecate.shuffle()
	var numar_sosuri = randi_range(1, 2)
	for i in range(numar_sosuri):
		comanda_mea.append(sosuri_amestecate[i])
		
	# 4. SUCUL (Avem, să zicem, 50% șanse ca un client să ceară și un suc la final)
	var sucul_ales = sucuri_disponibile.pick_random()
	comanda_mea.append(sucul_ales)

# _ready se execută imediat ce apare clientul în scenă
func _ready():
	pregateste_client_nou()
	pornește_animatie_buton()
	
# Funcție chemată de fiecare dată când un client vine la ușă
func pregateste_client_nou():
	genereaza_comanda_random()
	a_dat_comanda = false
	rabdare_curenta = rabdare_maxima
	rata_curenta = rata_scadere_coada # Începe alert!
	scade_rabdare = true
	set_process(true)

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
func _process(delta):
	if scade_rabdare and rabdare_curenta > 0:
		# Acum scade folosind rata_curenta (care se va schimba!)
		rabdare_curenta -= rata_curenta * delta
		if rabdare_curenta <= 0:
			rabdare_curenta = 0
			scade_rabdare = false
			set_process(false)
			patience_expired.emit()

# Modifică funcția de click ca să oprească scăderea răbdării:
func _on_texture_button_pressed():
	if a_dat_comanda == false:
		# MAGIA AICI: Nu mai oprim răbdarea, ci trecem pe viteza mică!
		rata_curenta = rata_scadere_gatit 
		
		a_fost_apasat.emit(comanda_mea)
		a_dat_comanda = true
