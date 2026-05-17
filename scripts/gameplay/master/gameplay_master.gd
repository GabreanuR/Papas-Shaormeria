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
	station.show()

func _go_to_order() -> void:
	_show_only(_order_station)

func _go_to_cutting() -> void:
	_show_only(_cutting_station)

func _go_to_assembly() -> void:
	_show_only(_assembly_station)

func _go_to_wrapping() -> void:
	_show_only(_wrapping_station)

# ---------------------------------------------------------
# 10. SIGNAL CALLBACKS
# ---------------------------------------------------------
func _on_day_ended() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/day_transition.tscn")
