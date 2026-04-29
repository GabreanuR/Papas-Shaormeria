extends Node2D

var comanda_mea: Array = [] # O lăsăm goală la început
signal a_fost_apasat(ingrediente)
var a_dat_comanda: bool = false 

# Lista cu "meniul" de unde putem alege (fără lipie)
# ATENȚIE: Cuvintele de aici trebuie să fie scrise EXACT cum le vei scrie în dicționarul din bilet!
var ingrediente_disponibile: Array = [
	"ardei", "carne_pui", "carne_vita", "cartofi", 
	"castraveti_murati", "ceapa", "chilli_flakes", 
	"ketchup_dulce", "ketchup_picant", "maioneza", 
	"maioneza_picanta", "maioneza_usturoi", "rosii", 
	"salata", "varza"
]

# _ready se execută imediat ce apare clientul în scenă
func _ready():
	genereaza_comanda_random()

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

# Aceasta este NOUA functie generata de TextureButton
func _on_texture_button_pressed():
	if a_dat_comanda == false:
		a_fost_apasat.emit(comanda_mea)
		a_dat_comanda = true
