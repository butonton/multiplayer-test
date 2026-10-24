extends Node

signal message_received(text: String)

var typing: bool = false

@rpc("any_peer", "call_local", "reliable")
func send_message(text: String) -> void:
	if not multiplayer.is_server():
		return
	text = text.strip_edges().left(200)
	if text.is_empty():
		return
	var sender = multiplayer.get_remote_sender_id()
	if sender == 0:
		sender = 1  # хост викликає сам себе
	broadcast_message.rpc("%s: %s" % [NetworkManager.get_nick(sender), text])

@rpc("authority", "call_local", "reliable")
func broadcast_message(text: String) -> void:
	message_received.emit(text)
