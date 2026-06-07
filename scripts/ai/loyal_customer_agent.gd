extends Node
class_name LoyalCustomerAgent

const CustomerHistoryScript = preload("res://scripts/ai/customer_history.gd")

signal dialogue_ready(text: String)

@export var ollama_url := "http://localhost:11434/api/generate"
@export var model_name := "llama3.2"

var http_request: HTTPRequest
var _current_history: Array = []

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

func generate_dialogue(order: Array) -> void:
	var history := CustomerHistoryScript.load_history()
	_current_history = history

	print("====== PAPA DEBUG ======")
	print("Current save: ", Global.current_save)
	print("Day: ", Global.current_save.get("day", -999))
	print("History size: ", history.size())
	print("========================")

	var ziua_curenta := int(Global.current_save.get("day", 1))

	var este_prima_vizita_reala := ziua_curenta == 1
	var has_history := not history.is_empty()
	var last_visit_summary := _build_last_visit_summary(history)

	var prompt := """
You are Papalouie, a customer at Papa's Shaormeria.

You are NOT the cashier.
You are NOT an employee.
Never welcome the player.
Never talk about today's order.

Current game day: %s
Last visit memory: %s

STRICT RULES:
- If Current game day is 1, say this is your first time here.
- If Current game day is greater than 1, NEVER say this is your first visit.
- If Current game day is greater than 1, NEVER say "first time here".
- Talk only about the previous visit.
- Mention the final score.
- Briefly explain why the score was good or bad.
- Use EXACTLY ONE sentence.
- Maximum 15 words.
- Return only dialogue text.
""" % [
	str(ziua_curenta),
	last_visit_summary
]

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
		
func _build_last_visit_summary(history: Array) -> String:
	if history.is_empty():
		return "No previous visit."

	var last_entry: Dictionary = history.back()

	var score := int(last_entry.get("score", 100))
	var waiting := int(last_entry.get("waiting", score))
	var cutting := int(last_entry.get("cutting", score))
	var assembly := int(last_entry.get("assembly", score))
	var wrapping := int(last_entry.get("wrapping", score))

	var weakest_name := "overall"

	if waiting > 0 and waiting <= cutting and waiting <= assembly and waiting <= wrapping:
		weakest_name = "waiting"
	elif cutting > 0 and cutting <= assembly and cutting <= wrapping:
		weakest_name = "cutting"
	elif assembly > 0 and assembly <= wrapping:
		weakest_name = "assembly"
	elif wrapping > 0:
		weakest_name = "wrapping"

	return "Final score %d, weakest category %s." % [score, weakest_name]

func _on_request_completed(
	_result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if response_code != 200:
		dialogue_ready.emit(_fallback_dialogue(_current_history))
		return

	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		dialogue_ready.emit(_fallback_dialogue(_current_history))
		return

	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		dialogue_ready.emit(_fallback_dialogue(_current_history))
		return

	var response := str(data.get("response", "")).strip_edges()
	var ziua_curenta := int(Global.current_save.get("day", 1))

	if ziua_curenta > 1:
		var lower := response.to_lower()

		if (
			lower.contains("first time") or
			lower.contains("first visit") or
			lower.contains("my first visit") or
			lower.contains("it's my first time") or
			lower.contains("this is my first time")
		):
			response = _fallback_dialogue(_current_history)
	if response == "":
		response = _fallback_dialogue(_current_history)

	if _current_history.is_empty() and _sounds_like_returning_customer(response):
		response = _fallback_dialogue(_current_history)

	dialogue_ready.emit(response)

func _sounds_like_returning_customer(text: String) -> bool:
	var lower := text.to_lower()
	return (
		lower.contains("back") or
		lower.contains("again") or
		lower.contains("last time") or
		lower.contains("previous") or
		lower.contains("remember last")
	)

func _fallback_dialogue(history: Array) -> String:
	var ziua_curenta := int(Global.current_save.get("day", 1))

	if ziua_curenta == 1:
		return "Hi, I'm Papalouie. It's my first time here, but I have a great memory, so I'll remember how things go."

	if history.is_empty():
		return "I'm back again. I don't remember much about my last visit, but I'm curious to see how things go today."

	var last_entry: Dictionary = history.back()

	var score := int(last_entry.get("score", 100))
	var waiting := int(last_entry.get("waiting", score))
	var cutting := int(last_entry.get("cutting", score))
	var assembly := int(last_entry.get("assembly", score))
	var wrapping := int(last_entry.get("wrapping", score))

	var weakest: int = int(min(waiting, cutting, assembly, wrapping))
	if score >= 95:
		return "I'm back again. Last time everything was excellent and I left very impressed. My final score was %d." % score

	if weakest == waiting:
		return "I'm back. Last time the wait felt a little longer than I hoped, even though the food was decent. My final score was %d." % score

	if weakest == cutting:
		return "I'm back. Last time the meat could have been cut more carefully, and that stood out to me. My final score was %d." % score

	if weakest == assembly:
		return "I'm back. Last time the ingredients weren't put together quite as well as they could have been. My final score was %d." % score

	if weakest == wrapping:
		return "I'm back. Last time the wrapping wasn't very clean, even though the rest was pretty good. My final score was %d." % score

	if score < 70:
		return "I'm back. I remember being pretty disappointed with my last order. My final score was only %d." % score

	return "I'm back again. Last time had some good moments and some things that could be improved. My final score was %d." % score
