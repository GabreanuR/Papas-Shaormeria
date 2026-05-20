extends Node

# ---------------------------------------------------------
# 1. SIGNALS
# ---------------------------------------------------------

# ---------------------------------------------------------
# 2. ENUMS
# ---------------------------------------------------------

# ---------------------------------------------------------
# 3. CONSTANTS
# ---------------------------------------------------------

# ---------------------------------------------------------
# 4. PUBLIC VARIABLES
# ---------------------------------------------------------
# Aceasta este lipia fizică pe care o prepari ACUM. 
# Când o livrezi, o resetezi.
#dictionar modificat de maia
var current_pita_state: Dictionary = {
	"meat_type": "",
	"is_cut": false,
	"sauces": [],
	"vegetables": [],

	"scores": {
		"cutting": 0,
		"waiting": 0,
		"assembly": 0,
		"wrapping": 0
	},

	"total_score": 0
}

#functii adaugate de maia
func update_station_score(station_name: String, score: int) -> void:
	current_pita_state["scores"][station_name] = score

	var total := 0
	for station_score in current_pita_state["scores"].values():
		total += station_score

	current_pita_state["total_score"] = total


func save_current_pita() -> void:
	completed_pitas.append(current_pita_state.duplicate(true))

	current_pita_state = {
		"meat_type": "",
		"is_cut": false,
		"sauces": [],
		"vegetables": [],
		"scores": {
			"cutting": 0,
			"waiting": 0,
			"assembly": 0,
			"wrapping": 0
		},
		"total_score": 0
	}
	
#am terminat cu functiile adaugate de maia

var completed_pitas: Array[Dictionary] = []
# ---------------------------------------------------------
# 5. PRIVATE VARIABLES
# ---------------------------------------------------------

# ---------------------------------------------------------
# 6. ONREADY VARIABLES
# ---------------------------------------------------------
@onready var _order_station: Node = %OrderStation
@onready var _cutting_station: Node = %MeatSelect
@onready var _assembly_station: Node = %AssemblyStation
@onready var _wrapping_station: Node = %WrappingStation

@onready var _btn_order: Button = %BtnOrder
@onready var _btn_cutting: Button = %BtnCutting
@onready var _btn_assembly: Button = %BtnAssembly
@onready var _btn_wrapping: Button = %BtnWrapping
var _next_to_wrapping_button: Button

# ---------------------------------------------------------
# 7. GODOT ENGINE FUNCTIONS
# ---------------------------------------------------------
func _ready() -> void:
	_btn_order.pressed.connect(_go_to_order)
	_btn_cutting.pressed.connect(_go_to_cutting)
	_btn_assembly.pressed.connect(_go_to_assembly)
	_btn_wrapping.pressed.connect(_go_to_wrapping)

	# Navigate to the day transition screen when the day ends.
	Global.day_ended.connect(_on_day_ended)
	_create_next_to_wrapping_button()

	# Start on the order station by default.
	_go_to_order()

# ---------------------------------------------------------
# 8. PUBLIC FUNCTIONS
# ---------------------------------------------------------

# ---------------------------------------------------------
# 9. PRIVATE FUNCTIONS
# ---------------------------------------------------------

## Shows only the given station and hides all others.
func _show_only(station: Node) -> void:
	_order_station.hide()
	_cutting_station.hide()
	_assembly_station.hide()
	_wrapping_station.hide()

	if _next_to_wrapping_button:
		_next_to_wrapping_button.visible = false

	station.show()

func _go_to_order() -> void:
	_show_only(_order_station)


#modificate de maia
func _go_to_cutting() -> void:
	_show_only(_cutting_station)


func _go_to_assembly() -> void:
	_show_only(_assembly_station)

	var lipie = _assembly_station.find_child("Lipie", true, false)
	if lipie and lipie.has_method("update_from_cutting"):
		lipie.update_from_cutting()

	if _next_to_wrapping_button:
		_next_to_wrapping_button.visible = true

func _go_to_wrapping() -> void:
	_show_only(_wrapping_station)
#sfarsit	

# ---------------------------------------------------------
# 10. SIGNAL CALLBACKS
# ---------------------------------------------------------
func _on_day_ended() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/day_transition.tscn")
	
func _create_next_to_wrapping_button() -> void:
	_next_to_wrapping_button = Button.new()
	_next_to_wrapping_button.text = "➜"
	_next_to_wrapping_button.position = Vector2(1680, 860)
	_next_to_wrapping_button.size = Vector2(120, 80)
	_next_to_wrapping_button.visible = false
	_next_to_wrapping_button.z_index = 999

	$CanvasLayer.add_child(_next_to_wrapping_button)
	_next_to_wrapping_button.pressed.connect(_send_assembly_to_wrapping)


func _send_assembly_to_wrapping() -> void:
	var lipie_container = _assembly_station.find_child("LipieContainer", true, false)

	if _wrapping_station.has_method("receive_pita_from_assembly"):
		_wrapping_station.receive_pita_from_assembly(lipie_container, current_pita_state)

	_go_to_wrapping()
