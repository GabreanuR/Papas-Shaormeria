extends Control

signal back_requested

@onready var close_button: TextureButton = $ReceiptNote/BtnCloseCredits
@onready var overlay: ColorRect = $ModalOverlay
@onready var receipt_node: TextureRect = $ReceiptNote

func play_credits() -> void:
	show()
	
	# Re-enable the close button in case this menu is re-opened after a previous close
	close_button.disabled = false
	
	var viewport_h: float = get_viewport_rect().size.y
	
	# 1. Position the receipt just below the visible screen before animating in
	receipt_node.position.y = viewport_h + receipt_node.size.y
	
	# 2. Start the dark overlay fade
	overlay.fade_in(0.85, 0.5)
	
	# 3. Animate the receipt bouncing in to a resting spot near the top
	var rest_y: float = get_viewport_rect().size.y * 0.05 * -1.0  # ~5% above centre
	var tween := create_tween()
	tween.tween_property(receipt_node, "position:y", rest_y, 0.8)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

func _on_close_button_pressed() -> void:
	close_button.disabled = true
	
	back_requested.emit()
	
	# 1. Start fading out the overlay
	overlay.fade_out(0.6)
	
	# 2. Animate the receipt flying up and off the top of the screen
	var exit_y: float = -(get_viewport_rect().size.y + receipt_node.size.y)
	var tween := create_tween()
	tween.tween_property(receipt_node, "position:y", exit_y, 0.6)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)
	
	# Wait for the receipt to finish flying out before hiding the whole menu
	await tween.finished
	
	hide()
