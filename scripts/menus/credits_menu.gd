extends Control

signal back_requested

@onready var close_button: TextureButton = $ReceiptNote/BtnCloseCredits
@onready var overlay: ColorRect = $ModalOverlay
@onready var receipt_node: TextureRect = $ReceiptNote

func _ready() -> void:
	pass

func play_credits() -> void:
	show()
	
	# 1. Set the starting position exactly like the old callback did
	receipt_node.position.y = 1200
	
	# 2. Start the dark overlay fade
	overlay.fade_in(0.85, 0.5)
	
	# 3. Animate the receipt bouncing in
	var tween := create_tween()
	tween.tween_property(receipt_node, "position:y", -50, 0.8)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

func _on_close_button_pressed() -> void:
	# 1. Start fading out the overlay
	overlay.fade_out(0.6)
	
	# 2. Animate the receipt flying up and away
	var tween := create_tween()
	tween.tween_property(receipt_node, "position:y", -1200, 0.6)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)
		
	# Wait for the receipt animation to finish before destroying the menu
	await tween.finished
	
	hide()
	back_requested.emit()
