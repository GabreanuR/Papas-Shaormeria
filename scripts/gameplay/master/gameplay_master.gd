extends Node

# Luăm referințele către cele 4 stații ale tale
@onready var order_station = $OrderStation
@onready var cutting_station = $MeatSelect
@onready var assembly_station = $AssemblyStation
@onready var wrapping_station = $WrappingStation

# Luăm referințele către noile butoane pe care tocmai le-ai creat
@onready var btn_order = $CanvasLayer/Taskbar/BtnOrder
@onready var btn_cutting = $CanvasLayer/Taskbar/BtnCutting
@onready var btn_assembly = $CanvasLayer/Taskbar/BtnAssembly
@onready var btn_wrapping = $CanvasLayer/Taskbar/BtnWrapping

func _ready():
	# Conectăm click-urile
	btn_order.pressed.connect(_go_to_order)
	btn_cutting.pressed.connect(_go_to_cutting)
	btn_assembly.pressed.connect(_go_to_assembly)
	btn_wrapping.pressed.connect(_go_to_wrapping)
	
	# La început, suntem automat în Lobby
	_go_to_order()

func _go_to_order():
	order_station.show()
	cutting_station.hide()
	assembly_station.hide()
	wrapping_station.hide()

func _go_to_cutting():
	order_station.hide()
	cutting_station.show()
	assembly_station.hide()
	wrapping_station.hide()

func _go_to_assembly():
	order_station.hide()
	cutting_station.hide()
	assembly_station.show()
	wrapping_station.hide()

func _go_to_wrapping():
	order_station.hide()
	cutting_station.hide()
	assembly_station.hide()
	wrapping_station.show()
