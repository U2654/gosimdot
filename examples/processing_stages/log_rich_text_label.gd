extends RichTextLabel

@export var max_lines: int = 60
var message_queue: Array[String] = []

func _ready() -> void:
	bbcode_enabled = true
	scroll_following = true

func log_message(new_text: String):
	var formatted = _format_bbcode(new_text)
	message_queue.push_back(formatted)
	
	if message_queue.size() > max_lines:
		message_queue.pop_front()
	
	_update_display()

func _format_bbcode(raw: String) -> String:
	var msg = raw
	if msg.begins_with("Pre:"):
		msg = "[color=#38bdf8][b]PRE[/b][/color]  " + msg.substr(4)
	elif msg.begins_with("Main:"):
		msg = "[color=#fbbf24][b]MAIN[/b][/color] " + msg.substr(5)
	elif msg.begins_with("Post:"):
		msg = "[color=#a78bfa][b]POST[/b][/color] " + msg.substr(5)
		
	msg = msg.replace("clock: ", "[color=#94a3b8]t=[/color]")
	msg = msg.replace("arrival nb: ", "[color=#60a5fa]Arrival #[/color]")
	msg = msg.replace("serving nb: ", "[color=#fcd34d]Serving #[/color]")
	msg = msg.replace("leaving nb: ", "[color=#4ade80]Leaving #[/color]")
	msg = msg.replace("type: A", "[color=#f59e0b]Type A[/color]")
	msg = msg.replace("type: B", "[color=#06b6d4]Type B[/color]")
	msg = msg.replace("type A", "[color=#f59e0b]Type A[/color]")
	msg = msg.replace("type B", "[color=#06b6d4]Type B[/color]")
	msg = msg.replace("server: ", "[color=#c084fc]Server [/color]")
	msg = msg.replace("queue: ", "[color=#c084fc]Queue [/color]")
	return msg

func _update_display():
	clear()
	for msg in message_queue:
		append_text(msg + "\n")

