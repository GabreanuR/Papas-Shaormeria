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


# =================================================================
# AI AGENT STATISTICAL EVALUATION & BENCHMARKING (Reparat cu Loguri)
# =================================================================
var eval_total_runs := 10
var eval_current_run := 0
var eval_json_success := 0
var eval_hallucinations := 0
var eval_total_latency := 0.0
var eval_start_time := 0.0
var test_ingredients := ["carne_pui", "varza", "cartofi", "maioneza_usturoi"]

func run_statistical_evaluation() -> void:
	print("STARTING AI EVALUATION INFLUENCER: Running ", eval_total_runs, " requests...")
	eval_current_run = 0
	eval_json_success = 0
	eval_hallucinations = 0
	eval_total_latency = 0.0
	_send_next_eval_request()

func _send_next_eval_request() -> void:
	if eval_current_run >= eval_total_runs:
		_print_final_evaluation_report()
		return
		
	eval_start_time = Time.get_ticks_msec()
	
	var prompt = """You are a famous TikTok culinary influencer reviewing Papa's Shaormeria.
Write a super catchy, short viral review (MAXIMUM 15 words) in ENGLISH about the food. Use emojis.
Pick exactly ONE ingredient from the list below to declare as the next mega viral TikTok food trend.

Ingredients eaten (CHOOSE ONLY ONE FROM THIS LIST):
%s

CRITICAL: Return ONLY a valid JSON object. No markdown, no ```json formatting.
Format:
{
	"review": "Your short viral review...",
	"trend_ingredient": "exact_name_from_list"
}""" % str(test_ingredients)

	var body = {"model": "llama3.2", "prompt": prompt, "stream": false, "format": "json"}
	
	if http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		http_request.cancel_request()
	
	if http_request.request_completed.is_connected(_on_request_completed):
		http_request.request_completed.disconnect(_on_request_completed)
	
	if not http_request.request_completed.is_connected(_on_eval_request_completed):
		http_request.request_completed.connect(_on_eval_request_completed)
		
	var eval_url = "http://localhost:11434/api/generate"
	print("Sending evaluation request ", eval_current_run + 1, " to Ollama (Influencer)...")
	
	var err = http_request.request(eval_url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(body))
	
	if err != OK:
		print("GODOT ENGINE ERROR at request ", eval_current_run + 1, " - Error Code: ", err)
		eval_current_run += 1
		get_tree().create_timer(1.0).timeout.connect(_send_next_eval_request)

func _on_eval_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var end_time = Time.get_ticks_msec()
	eval_total_latency += (end_time - eval_start_time) / 1000.0
	eval_current_run += 1
	
	print("Request ", eval_current_run, " received a response! (Server Code: ", response_code, ")")
	
	if response_code == 200:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var data = json.get_data()
			var raw_response = str(data.get("response", "")).strip_edges()
			var response_json = JSON.parse_string(raw_response)
			
			if response_json and typeof(response_json) == TYPE_DICTIONARY:
				eval_json_success += 1
				
				var trend = response_json.get("trend_ingredient", "")
				if not trend in test_ingredients:
					eval_hallucinations += 1
					
	_send_next_eval_request()

func _print_final_evaluation_report() -> void:
	http_request.request_completed.disconnect(_on_eval_request_completed)
	http_request.request_completed.connect(_on_request_completed)
	
	print("\nAI METRICS REPORT: CULINARY INFLUENCER")
	print("Total Executed Batches: ", eval_total_runs)
	print("Valid JSON Output Rate: ", eval_json_success, " / ", eval_total_runs, " (", (float(eval_json_success)/eval_total_runs)*100, "%)")
	print("Hallucination Defect Count: ", eval_hallucinations, " / ", eval_total_runs, " (", (float(eval_hallucinations)/eval_total_runs)*100, "%)")
	print("Average Engine Latency: ", eval_total_latency / eval_total_runs, " seconds per request")
	print("==================================================\n")
