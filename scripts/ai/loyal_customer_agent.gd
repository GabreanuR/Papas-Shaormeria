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
	var ziua_curenta := int(Global.current_save.get("day", 1))
	var este_prima_vizita_reala := ziua_curenta == 1 and not has_history

	var memory_summary := _build_memory_summary(history)

	var prompt := """
You are Papalouie, the loyal recurring customer in Papa's Shaormeria.

You are NOT a generic NPC.
You are a recurring customer with memory.
You remember only the last 3 visits.

Current game day:
%s

Is this the real first visit:
%s

Memory summary:
%s

Current order:
%s

Rules:
Use only normal English characters.
Do not use emojis.
Do not use special symbols.
Write maximum 2 short sentences.
Each sentence must be short.

If this is the real first visit, introduce yourself as Papalouie.
Say this is your first visit and that you will remember mistakes.

If this is NOT the real first visit, NEVER say this is your first visit.
Mention something from the memory summary.
If memory is empty but day is higher than 1, say you are back and ready for another shaorma.

Return only the dialogue text.
""" % [
		str(ziua_curenta),
		str(este_prima_vizita_reala),
		memory_summary,
		str(order)
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


func _build_memory_summary(history: Array) -> String:
	if history.is_empty():
		return "No saved visits."

	var summaries: Array[String] = []

	for entry in history:
		var score := int(entry.get("score", 100))
		var order := str(entry.get("order", []))

		if score < 70:
			summaries.append("Previous visit was bad, score " + str(score) + ", order " + order + ".")
		else:
			summaries.append("Previous visit was good, score " + str(score) + ", order " + order + ".")

	return " ".join(summaries)


func _on_request_completed(
	_result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	var history := CustomerHistoryScript.load_history()

	if response_code != 200:
		dialogue_ready.emit(_fallback_dialogue(history))
		return

	var json := JSON.new()
	var err := json.parse(body.get_string_from_utf8())

	if err != OK:
		dialogue_ready.emit(_fallback_dialogue(history))
		return

	var data = json.get_data()

	if typeof(data) != TYPE_DICTIONARY:
		dialogue_ready.emit(_fallback_dialogue(history))
		return

	var response := str(data.get("response", "")).strip_edges()
	dialogue_ready.emit(_sanitize_dialogue(response))


func _sanitize_dialogue(text: String) -> String:
	var history := CustomerHistoryScript.load_history()

	var regex := RegEx.new()
	regex.compile("[^a-zA-Z0-9 .,!?':\\-\\n]")

	var clean := regex.sub(text, "", true)
	clean = clean.strip_edges()

	while clean.contains("  "):
		clean = clean.replace("  ", " ")

	if clean == "":
		return _fallback_dialogue(history)

	var sentence_regex := RegEx.new()
	sentence_regex.compile("[^.!?]+[.!?]")

	var matches := sentence_regex.search_all(clean)
	var final_sentences: Array[String] = []

	for match_result in matches:
		var sentence := match_result.get_string().strip_edges()
		sentence = _limit_sentence_words(sentence, 13)

		if sentence != "":
			final_sentences.append(sentence)

		if final_sentences.size() >= 2:
			break

	if final_sentences.is_empty():
		return _limit_sentence_words(clean, 13)

	return " ".join(final_sentences)


func _limit_sentence_words(sentence: String, max_words: int) -> String:
	var ending := "."

	if sentence.ends_with(".") or sentence.ends_with("!") or sentence.ends_with("?"):
		ending = sentence[-1]
		sentence = sentence.substr(0, sentence.length() - 1).strip_edges()

	var words := sentence.split(" ", false)

	if words.size() > max_words:
		words = words.slice(0, max_words)

	var result := " ".join(words).strip_edges()

	if result == "":
		return ""

	return result + ending


func _fallback_dialogue(history: Array) -> String:
	var ziua_curenta := int(Global.current_save.get("day", 1))

	if history.is_empty():
		if ziua_curenta == 1:
			return "Hi, I'm Papalouie! This is my first visit, and I'll remember mistakes."
		else:
			return "I'm back again! I may be fuzzy today, but I remember this place."

	var last_entry: Dictionary = history.back()
	var score := int(last_entry.get("score", 100))

	if score < 70:
		return "I'm back, and I remember last time wasn't great. Please do better today."

	return "I'm back again! I remember last time was pretty good."
