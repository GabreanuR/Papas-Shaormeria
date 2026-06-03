extends Node
class_name CulinaryInfluencerAgent

signal review_ready(review_text: String, trend_ingredient: String)

@export var ollama_url := "http://localhost:11434/api/generate"
@export var model_name := "llama3.2"

var http_request: HTTPRequest

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

func generate_review(shaorma_ingredients: Array) -> void:
	var prompt := """
You are a famous food critic and TikTok culinary influencer visiting Papa's Shaormeria.
Analyze this shaorma configuration and write a short, funny, trendy review (max 2 sentences).
Also, pick ONE main ingredient from the list to declare as the next big viral food trend.

Ingredients eaten:
%s

CRITICAL: You must return ONLY a valid JSON object. Do not include markdown formatting like ```json or any other text.
Format:
{
	"review": "Your review text here...",
	"trend_ingredient": "the_ingredient_name"
}
""" % str(shaorma_ingredients)

	var body := {
		"model": model_name,
		"prompt": prompt,
		"stream": false,
		"format": "json"
	}

	var headers := ["Content-Type: application/json"]
	# Dacă nodul e deja ocupat cu altă cerere, o anulează pe aia veche ca să facă loc
	if http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		http_request.cancel_request()

	http_request.request(ollama_url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

#func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	#if response_code != 200:
		#review_ready.emit("This shaorma is bussing! Next trend is falafel.", "falafel")
		#return
#
	#var json := JSON.new()
	#if json.parse(body.get_string_from_utf8()) != OK:
		#review_ready.emit("Amazing taste! Next trend is falafel.", "falafel")
		#return
#
	#var data = json.get_data()
	#if typeof(data) == TYPE_DICTIONARY:
		#var raw_response := str(data.get("response", "")).strip_edges()
		#
		#var response_json = JSON.parse_string(raw_response)
		#if response_json and typeof(response_json) == TYPE_DICTIONARY:
			#var review = response_json.get("review", "Amazing!")
			#var trend = response_json.get("trend_ingredient", "falafel")
			#review_ready.emit(review, trend)
			#return
			#
	#review_ready.emit("Incredible taste! You must try it with extra garlic.", "maioneza_usturoi")


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	
	# === CAPCANELE NOASTRE DE DEBUG ===
	print("\n--- 🚨 INVESTIGAȚIE OLLAMA ---")
	print("Cod Rezultat intern Godot (0 înseamnă că s-a conectat cu succes): ", result)
	print("Cod Răspuns Server (200 înseamnă OK): ", response_code)
	
	var text_primit = body.get_string_from_utf8()
	print("Ce a zis efectiv Ollama: ", text_primit)
	print("--------------------------------\n")
	# ==================================

	if response_code != 200:
		review_ready.emit("This shaorma is bussing! Next trend is falafel.", "falafel")
		return

	var json := JSON.new()
	if json.parse(text_primit) != OK:
		print("❌ EROARE: Ollama nu a răspuns cu un JSON valid!")
		review_ready.emit("Amazing taste! Next trend is falafel.", "falafel")
		return

	var data = json.get_data()
	if typeof(data) == TYPE_DICTIONARY:
		var raw_response := str(data.get("response", "")).strip_edges()
		
		var response_json = JSON.parse_string(raw_response)
		if response_json and typeof(response_json) == TYPE_DICTIONARY:
			var review = response_json.get("review", "Amazing!")
			var trend = response_json.get("trend_ingredient", "falafel")
			
			print("✅ SUCCES: Ollama a ales trendul: ", trend)
			review_ready.emit(review, trend)
			return
		else:
			print("❌ EROARE: Răspunsul brut nu a putut fi transformat în dicționar.")
			
	review_ready.emit("Incredible taste! You must try it with extra garlic.", "maioneza_usturoi")
