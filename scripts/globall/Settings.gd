extends Node

const SAVE_PATH = "user://settings.cfg"

var nickname: String = "Player"

func _ready():
	load_settings()

func save_settings():
	var config = ConfigFile.new()

	config.set_value("player", "nickname", nickname)

	config.save(SAVE_PATH)

func load_settings():
	var config = ConfigFile.new()
	var error = config.load(SAVE_PATH)

	if error == OK:
		nickname = config.get_value("player", "nickname", "Player")
