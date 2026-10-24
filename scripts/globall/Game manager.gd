extends Node

var round_active: bool = true

func _ready() -> void:
	pass

@rpc("any_peer", "call_local")
func on_player_died(dead_player_name: String) -> void:
	if not multiplayer.is_server():
		return
	if not round_active:
		return
	
	check_win_condition()

func check_win_condition() -> void:
	var arena = get_tree().current_scene
	var players_container = arena.get_node("PlayersContainer")
	
	var alive_players: Array[Node] = []
	for p in players_container.get_children():
		if not p.is_in_group("Player"):
			continue
		if p.isAlive:
			alive_players.append(p)
	
	if alive_players.size() <= 1:
		round_active = false
		var winner_name = "Нічия"
		if alive_players.size() == 1:
			var winner_id = int(str(alive_players[0].name))
			winner_name = NetworkManager.get_nick(winner_id)
		show_winner.rpc(winner_name)
		await get_tree().create_timer(3.0).timeout
		restart_round.rpc()
		
		show_winner.rpc(winner_name)
		await get_tree().create_timer(3.0).timeout
		restart_round.rpc()

@rpc("any_peer", "call_local")
func show_winner(winner_name: String = '0') -> void:
	var win_label = get_tree().current_scene.get_node("UI/WinLabel")  
	win_label.text = "Переміг: " + winner_name
	win_label.visible = true

@rpc("any_peer", "call_local")
func restart_round() -> void:
	var win_label = get_tree().current_scene.get_node("UI/WinLabel")
	win_label.visible = false
	
	if multiplayer.is_server():
		round_active = true
		respawn_all_players()

func respawn_all_players() -> void:
	var arena = get_tree().current_scene
	var players_container = arena.get_node("PlayersContainer")
	var spawn_points = arena.spawn_points
	
	var index = 0
	for p in players_container.get_children():
		if not p.is_in_group("Player"):
			continue
		p.hp = 100.0
		p.isAlive = true
		p.update_hp.rpc(p.hp, true)
		p.teleport_to.rpc(spawn_points[index % spawn_points.size()].global_position)
		index += 1
