extends Control

@onready var ip_input: LineEdit = $"main menu/IPInput"
@onready var nick_input: LineEdit = $"main menu/nickInput"

func _ready():
	nick_input.text = Settings.nickname
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		$"main menu/error".text = "З'єднання з сервером втрачено"



func _save_nick() -> void:
	
	Settings.nickname = nick_input.text.strip_edges()
	Settings.save_settings()
	NetworkManager.local_nick = nick_input.text.strip_edges()

func _on_host_button_pressed() -> void:
	_save_nick()
	
	$"main menu".visible = false
	$Control.visible = true

func _on_join_button_pressed() -> void:
	var ip = ip_input.text
	if ip.is_empty():
		ip = "127.0.0.1"
	_save_nick()
	NetworkManager.join_game(ip)


func _on_button_pressed() -> void:
	$"main menu".visible = true
	$Control.visible = false

func _on_dev_arena_pressed() -> void:
	NetworkManager.arena_count = -1
	NetworkManager.host_game()

func _on_arena_1_pressed() -> void:
	NetworkManager.current_map = NetworkManager.MAPS[0]
	NetworkManager.host_game()

func _on_arena_2_pressed() -> void:
	NetworkManager.current_map = NetworkManager.MAPS[1]
	NetworkManager.host_game()

func _on_arena_3_pressed() -> void:
	NetworkManager.current_map = NetworkManager.MAPS[2]
	NetworkManager.host_game()
