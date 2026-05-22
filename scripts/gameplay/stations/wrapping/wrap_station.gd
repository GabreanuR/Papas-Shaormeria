extends Control # Rădăcina trebuie să fie Control pentru a accepta Drag & Drop

@onready var wrap_area = $WrapGestureArea
@onready var tray = $Tray
@onready var ticket = $Ticket # Acesta este doar un bilet "de fațadă" (placeholder)
@onready var ticket_slot_sprite = $Tray/TicketSlot/Sprite2D
@onready var send_button = $Tray/SendButton
@onready var darken = $Tray/SendButton/Darken
@onready var fade = $FadeOverlay

var assembled_pita: Node2D = null

var wrap_quality: float = 0.0
var ticket_placed := false

func _ready() -> void:
	wrap_area.wrap_completed.connect(_on_wrap_done)

	# Ascundem biletul local la început; el apare doar când dăm drop cu succes
	ticket.hide()
	ticket.z_index = 200

	send_button.visible = true
	darken.visible = true
	darken.modulate.a = 0.65

	fade.modulate.a = 0.0

func _on_wrap_done(quality: float) -> void:
	wrap_quality = quality
	# Nu mai e nevoie de `can_drag_ticket`. Faptul că wrap_quality > 0 
	# este suficient pentru a debloca primirea biletului în _can_drop_data.

# ==========================================
# MAGIA DRAG & DROP NATIV
# ==========================================

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# Stația acceptă biletul doar dacă shaorma a fost împachetată 
	# și dacă datele vin cu adevărat de la un bilet.
	return wrap_quality > 0.0 and typeof(data) == TYPE_DICTIONARY and data.has("este_bilet_comanda")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	ticket_placed = true

	# 1. Distrugem fizic biletul tridimensional/original de pe șina din TopBar
	if is_instance_valid(data["nod_bilet"]):
		print("Se pregătește livrarea pentru clientul: ", data["numar_client"])
		# TODO: Aici vei extrage ingredientele din data["nod_bilet"] pentru a calcula scorul final
		data["nod_bilet"].queue_free()

	# 2. Arătăm biletul "placeholder" de pe tavă pentru feedback vizual
	ticket.global_position = ticket_slot_sprite.global_position
	ticket.reparent(tray)
	ticket.show()

	# 3. Activăm butonul de trimitere
	darken.visible = false
	darken.modulate.a = 0.0

# ==========================================
# INTERACȚIUNEA CU BUTONUL SEND
# ==========================================

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if ticket_placed and is_mouse_over_send(get_global_mouse_position()):
			get_viewport().set_input_as_handled()
			_on_send_pressed()

func _on_send_pressed() -> void:
	if not ticket_placed:
		return

	var tween := create_tween()
	tween.tween_property(tray, "position:x", tray.position.x + 1800, 0.85)

	var fade_tween := create_tween()
	fade_tween.tween_property(fade, "modulate:a", 1.0, 0.85)
	
	# Aici vei emite probabil un semnal către GameplayMaster că s-a finalizat comanda!

func is_mouse_over_send(mouse_pos: Vector2) -> bool:
	return mouse_pos.distance_to(send_button.global_position) < 120.0

# ==========================================
# TRANSFERUL DE LA ASSEMBLY
# ==========================================

func receive_pita_from_assembly(source_lipie_container: Node, _pita_state: Dictionary) -> void:
	if source_lipie_container == null:
		return

	source_lipie_container.reparent(tray)
	source_lipie_container.visible = true

	source_lipie_container.scale = Vector2(0.45, 0.45)
	source_lipie_container.z_index = 100

	var lipie_sprite := source_lipie_container.find_child("Lipie", true, false)

	if lipie_sprite:
		var target_global_pos := Vector2(820, 600)
		var current_lipie_global_pos: Vector2 = lipie_sprite.global_position
		var offset := target_global_pos - current_lipie_global_pos

		source_lipie_container.global_position += offset
	else:
		source_lipie_container.position = Vector2.ZERO
