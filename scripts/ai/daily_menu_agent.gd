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
