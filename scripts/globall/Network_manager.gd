extends Node

const PORT = 7777
const MAX_PLAYERS = 2

var players: Dictionary = {}

const MAPS = [
	"res://scenes/arens/arena.tscn",
	"res://scenes/arens/arena_2.tscn",
	"res://scenes/arens/arena_3.tscn",
	"res://scenes/dev_arena.tscn" # свої шляхи
]



var current_map: String = MAPS[0]

@export var arena_count:int = 0

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_game() -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		print("Помилка створення сервера: ", error)
		return
	multiplayer.multiplayer_peer = peer
	print("Сервер створено, очікуємо гравців...")
	print("arena_count = ", arena_count)
	get_tree().change_scene_to_file(current_map)
	
	nicknames[1] = _clean_nick(local_nick, 1)
	sync_nicknames.rpc(nicknames)

func join_game(ip: String) -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, PORT)
	if error != OK:
		print("Помилка підключення: ", error)
		return
	multiplayer.multiplayer_peer = peer
	print("Підключення до ", ip, "...")
	

func _on_peer_connected(id: int) -> void:
	print("Гравець підключився: ", id)
	if multiplayer.is_server():
		load_map.rpc_id(id, MAPS.find(current_map))

@rpc("authority", "reliable")
func load_map(index: int) -> void:
	var path = MAPS[index]
	get_tree().change_scene_to_file(path)
	while get_tree().current_scene == null or get_tree().current_scene.scene_file_path != path:
		await get_tree().process_frame
	client_scene_ready.rpc_id(1)

@rpc("any_peer", "reliable")
func client_scene_ready() -> void:
	if not multiplayer.is_server():
		return
	var arena = get_tree().current_scene
	if not arena.get_node("PlayersContainer").has_node("1"):
		arena.spawn_player(1)  # хост з'являється одночасно з клієнтом
	arena.spawn_player(multiplayer.get_remote_sender_id())

func _on_peer_disconnected(id: int) -> void:
	print("Гравець відключився: ", id)
	if not multiplayer.is_server():
		return
	# Отримуємо нікнейм гравця до видалення
	var nick = get_nick(id)
	broadcast_message(nick + " відключився!")
	# Видаляємо гравця зі списку нікнеймів
	nicknames.erase(id)
	sync_nicknames.rpc(nicknames)
	# Видаляємо його персонажа
	var players = get_tree().current_scene.get_node_or_null("PlayersContainer")
	if players:
		var player = players.get_node_or_null(str(id))
		if player:
			player.queue_free()

func _on_connected_to_server() -> void:
	print("Успішно підключено до сервера!")
	# сцену не міняємо, чекаємо load_map від сервера

func _on_connection_failed() -> void:
	print("Не вдалось підключитись")
	var errorLine = get_tree().current_scene.get_node_or_null('error')
	if errorLine:
		errorLine.text("Не вдалось підключитись")

func _on_server_disconnected() -> void:
	print("З'єднання з сервером втрачено")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func disconnect_from_server():
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func broadcast_message(message: String) -> void:
	if not multiplayer.is_server():
		return
	show_message.rpc(message)


@rpc("authority", "call_local", "reliable")
func show_message(message: String) -> void:
	var console = get_tree().get_first_node_in_group("Console")
	if console:
		console.add_message(message)
	else:
		print(console)

var local_nick: String = ""
var nicknames: Dictionary = {}  # peer_id -> нік

func _clean_nick(raw: String, id: int) -> String:
	var nick = raw.strip_edges().left(16)
	if nick.is_empty():
		nick = "Гравець %d" % id
	return nick

@rpc("any_peer", "reliable")
func register_nick(nick: String) -> void:
	if not multiplayer.is_server():
		return
	var id = multiplayer.get_remote_sender_id()
	nicknames[id] = _clean_nick(nick, id)
	sync_nicknames.rpc(nicknames)
	broadcast_message(get_nick(id) + " підключився!")

@rpc("authority", "call_local", "reliable")
func sync_nicknames(data: Dictionary) -> void:
	nicknames = data

func get_nick(id: int) -> String:
	return nicknames.get(id, "Гравець %d" % id)


# PlayersContainer/MultiplayerSpawner
