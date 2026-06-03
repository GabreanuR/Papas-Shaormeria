extends Node
class_name LoyalCustomerAgent

const CustomerHistoryScript = preload("res://scripts/ai/customer_history.gd")

signal dialogue_ready(text: String)

@export var ollama_url := "http://localhost:11434/api/generate"
@export var model_name := "llama3.2"

var http_request: HTTPRequest


func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)


func generate_dialogue(order: Array) -> void:
	var history := CustomerHistoryScript.load_history()
	var has_history := CustomerHistoryScript.has_any_history()

	var prompt := """
You are Papalouie, the loyal recurring customer in a funny Papa's Shaormeria game.

You are always the first customer of the day.
You have a very good memory.
You remember only the last 3 visits.
Speak naturally, shortly, and like a returning customer.

If this is your first saved interaction, do NOT say you are back. Say this is your first visit here, introduce yourself, and clearly say that you have a very good memory and that you will remember mistakes from now on.
If the player made mistakes before, mention one politely.
If the previous visit was good, mention that you remember it.

Current order:
%s

Hidden memory:
%s

Has previous memory:
%s

Return only the customer dialogue text.
Maximum 2 sentences.
""" % [str(order), JSON.stringify(history), str(has_history)]

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
		return "Hi, I'm Papalouie! This is my first visit here. I have a very good memory, so I'll remember every mistake from now on."

	var last_entry: Dictionary = history.back()
	var score := int(last_entry.get("score", 100))

	if score < 70:
		return "I'm back, and I remember last time wasn't great. Please don't mess up my shaorma again."

	return "I'm back again! I remember last time was pretty good, so I trust you with another shaorma."
