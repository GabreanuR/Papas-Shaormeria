extends Node

signal daily_recipe_ready(recipe_array: Array)

var http_request: HTTPRequest

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

func generate_fusion_recipe(available_ingredients: Array):
	var url = "http://localhost:11434/api/generate"
	
	# Transformăm array-ul de ingrediente într-un string pentru prompt
	var ingredients_string = ", ".join(available_ingredients)
	
	var prompt = "You are a master chef creating a daily 'Fusion Shaorma' special. Create a creative but edible recipe using ONLY a selection of these exact ingredients: " + ingredients_string + ". You must include at least one meat, two vegetables, and one sauce. Return ONLY a valid JSON object with a single key 'fusion_recipe' containing an array of strings representing the chosen ingredients. Do not include any other text, markdown, or explanations."
	
	var body = JSON.stringify({
		"model": "llama3.2", # Schimbă cu modelul tău dacă folosești altceva (ex: mistral)
		"prompt": prompt,
		"stream": false,
		"format": "json"
	})
	
	var headers = ["Content-Type: application/json"]
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)

func _on_request_completed(_result, response_code, _headers, body):
	if response_code == 200:
		var response_text = body.get_string_from_utf8()
		var json = JSON.new()
		
		# Parsăm răspunsul inițial de la Ollama
		if json.parse(response_text) == OK:
			var data = json.get_data()
			var response_content = data.get("response", "")
			
			# Parsăm JSON-ul returnat în textul răspunsului
			var inner_json = JSON.new()
			if inner_json.parse(response_content) == OK:
				var recipe_data = inner_json.get_data()
				if recipe_data is Dictionary and recipe_data.has("fusion_recipe"):
					var final_recipe = recipe_data["fusion_recipe"]
					daily_recipe_ready.emit(final_recipe)
					return
					
	# Fallback de siguranță în caz că AI-ul dă rateu (pentru a nu bloca jocul)
	daily_recipe_ready.emit(["carne_pui", "cartofi", "varza", "maioneza_usturoi"])


# =================================================================
# AI AGENT STATISTICAL EVALUATION & BENCHMARKING (Reparat cu Loguri)
# =================================================================
var eval_total_runs := 3 # L-AM SCĂZUT LA 3 PENTRU TESTARE RAPIDĂ!
var eval_current_run := 0
var eval_json_success := 0
var eval_empty_recipes := 0
var eval_total_latency := 0.0
var eval_start_time := 0.0
var all_available_ingredients := ["carne_pui", "carne_vita", "falafel", "ardei", "cartofi", "varza"]

func run_statistical_evaluation() -> void:
	print("STARTING AI EVALUATION DAILY MENU: Running ", eval_total_runs, " requests...")
	eval_current_run = 0
	eval_json_success = 0
	eval_empty_recipes = 0
	eval_total_latency = 0.0
	_send_next_eval_request()

func _send_next_eval_request() -> void:
	if eval_current_run >= eval_total_runs:
		_print_final_evaluation_report()
		return
		
	eval_start_time = Time.get_ticks_msec()
	
	var ingredients_string = ", ".join(all_available_ingredients)
	var prompt = "You are a master chef creating a daily 'Fusion Shaorma' special. Create a creative but edible recipe using ONLY a selection of these exact ingredients: " + ingredients_string + ". You must include at least one meat, two vegetables, and one sauce. Return ONLY a valid JSON object with a single key 'fusion_recipe' containing an array of strings representing the chosen ingredients. Do not include any other text, markdown, or explanations."
	var body = {"model": "llama3.2", "prompt": prompt, "stream": false, "format": "json"}
	
	if http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		http_request.cancel_request()
	
	if http_request.request_completed.is_connected(_on_request_completed):
		http_request.request_completed.disconnect(_on_request_completed)
	
	if not http_request.request_completed.is_connected(_on_eval_request_completed):
		http_request.request_completed.connect(_on_eval_request_completed)
		
	var eval_url = "http://localhost:11434/api/generate"
	print("Sending evaluation request ", eval_current_run + 1, " to Ollama (Daily Menu)...")
	
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
				
				var recipe = response_json.get("fusion_recipe", [])
				if recipe.size() == 0:
					eval_empty_recipes += 1
					
	_send_next_eval_request()

func _print_final_evaluation_report() -> void:
	http_request.request_completed.disconnect(_on_eval_request_completed)
	http_request.request_completed.connect(_on_request_completed)
	
	print("\nAI METRICS REPORT: DAILY FUSION MENU")
	print("Total Executed Batches: ", eval_total_runs)
	print("Valid JSON Output Rate: ", eval_json_success, " / ", eval_total_runs, " (", (float(eval_json_success)/eval_total_runs)*100, "%)")
	print("Empty Recipe Failure Rate: ", eval_empty_recipes, " / ", eval_total_runs, " (", (float(eval_empty_recipes)/eval_total_runs)*100, "%)")
	print("Average Engine Latency: ", eval_total_latency / eval_total_runs, " seconds per request")
	print("==================================================\n")
