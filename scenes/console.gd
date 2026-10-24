extends Panel

@onready var messages: RichTextLabel = $Messages
@onready var input_container = $input_container
@onready var input: LineEdit = $input_container/MessageInput

const SHOW_TIME := 2.0

var chat_enabled: bool = false
var hide_timer: float = 0.0

func _ready() -> void:
	messages.scroll_following = true
	messages.modulate.a = 0.0
	input_container.visible = false
	ChatManager.message_received.connect(add_message)
	input.text_submitted.connect(_on_text_submitted)

func _process(delta: float) -> void:
	if chat_enabled:
		messages.modulate.a = 1.0
	else:
		hide_timer -= delta
		if hide_timer <= 0.0:
			messages.modulate.a = lerp(messages.modulate.a, 0.0, delta * 3.0)

func add_message(text: String) -> void:
	messages.add_text(text + "\n")
	messages.modulate.a = 1.0
	hide_timer = SHOW_TIME

func _unhandled_input(event: InputEvent) -> void:
	if not chat_enabled and event.is_action_pressed("ui_text_submit"):
		open_chat()
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if chat_enabled and event.is_action_pressed("ui_cancel"):
		close_chat()
		get_viewport().set_input_as_handled()

func _on_text_submitted(text: String) -> void:
	text = text.strip_edges()
	if text != "":
		ChatManager.send_message.rpc_id(1, text)
	input.text = ""
	close_chat()

func open_chat() -> void:
	chat_enabled = true
	ChatManager.typing = true
	input_container.visible = true
	input.grab_focus()

func close_chat() -> void:
	chat_enabled = false
	ChatManager.typing = false
	input_container.visible = false
	input.release_focus()
	hide_timer = SHOW_TIME
