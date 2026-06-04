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
	# Filtrăm băuturile din lista pe care o trimitem la AI, ca să nu aibă de unde să le aleagă!
	var ingrediente_filtrate = []
	var bauturi = ["suc_cola", "suc_portocale", "suc_lamaie"] 
	
	for ing in shaorma_ingredients:
		if not ing in bauturi:
			ingrediente_filtrate.append(ing)

	var prompt := """
You are a famous TikTok culinary influencer reviewing Papa's Shaormeria.
Write a super catchy, short viral review (MAXIMUM 15 words) in ENGLISH about the food. Use emojis.
Pick exactly ONE ingredient from the list below to declare as the next mega viral TikTok food trend.

Ingredients eaten (CHOOSE ONLY ONE FROM THIS LIST):
%s

CRITICAL: Return ONLY a valid JSON object. No markdown, no ```json formatting.
Format:
{
	"review": "Your short viral review...",
	"trend_ingredient": "exact_name_from_list"
}
""" % str(ingrediente_filtrate)

	var body := {
		"model": model_name,
		"prompt": prompt,
		"stream": false,
		"format": "json"
	}

	var headers := ["Content-Type: application/json"]
	if http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		http_request.cancel_request()

	http_request.request(ollama_url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		review_ready.emit("This shaorma is bussing! Next trend is falafel.", "falafel")
		return

	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		review_ready.emit("Amazing taste! Next trend is falafel.", "falafel")
		return

	var data = json.get_data()
	if typeof(data) == TYPE_DICTIONARY:
		var raw_response := str(data.get("response", "")).strip_edges()
		
		var response_json = JSON.parse_string(raw_response)
		if response_json and typeof(response_json) == TYPE_DICTIONARY:
			var review = response_json.get("review", "Amazing!")
			var trend = response_json.get("trend_ingredient", "falafel")
			review_ready.emit(review, trend)
			return
			
	review_ready.emit("Incredible taste! You must try it with extra garlic.", "maioneza_usturoi")
