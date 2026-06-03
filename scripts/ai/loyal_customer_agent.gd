extends Node
class_name LoyalCustomerAgent

const CustomerHistory = preload("res://scripts/ai/customer_history.gd")

signal dialogue_ready(text: String)

@export var ollama_url := "http://localhost:11434/api/generate"
@export var model_name := "llama3.2"

var http_request: HTTPRequest


func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)


func generate_dialogue(order: Array) -> void:
	var history := CustomerHistory.load_history()

	var prompt := """
You are a loyal recurring customer in a funny Papa's Shaormeria game.

You are the first customer of the day.
You remember only the last 3 visits.
Speak naturally, shortly, and like a returning customer.
If the player made mistakes before, mention it politely.
If there is no history, introduce yourself as a returning customer.

Current order:
%s

Hidden memory:
%s

Return only the dialogue text.
Maximum 2 sentences.
""" % [str(order), JSON.stringify(history)]

	var body := {
		"model": model_name,
		"prompt": prompt,
		"stream": false
	}

	var headers := ["Content-Type: application/json"]
	var err := http_request.request(
		ollama_url,
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(body)
	)

	if err != OK:
		dialogue_ready.emit(_fallback_dialogue(history))


func _on_request_completed(
	_result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if response_code != 200:
		dialogue_ready.emit("I'm back again! Please make my shaorma better than last time.")
		return

	var json := JSON.new()
	var err := json.parse(body.get_string_from_utf8())

	if err != OK:
		dialogue_ready.emit("Nice to see you again! I hope you remember my order.")
		return

	var data = json.get_data()

	if typeof(data) != TYPE_DICTIONARY:
		dialogue_ready.emit("I'm back again! Let's see if you still know how to make my favorite shaorma.")
		return

	var response := str(data.get("response", "")).strip_edges()

	if response == "":
		response = "I'm back again! I hope today's shaorma is perfect."

	dialogue_ready.emit(response)


func _fallback_dialogue(history: Array) -> String:
	if history.is_empty():
		return "Hi, I'm your loyal customer! Let's see if this becomes my favorite shaormeria."

	var last_entry: Dictionary = history.back()
	var score := int(last_entry.get("score", 100))

	if score < 70:
		return "I'm back, but last time wasn't great. Please don't mess up my shaorma again."

	return "I'm back again! Last time was pretty good, so I trust you with another shaorma."
