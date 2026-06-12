extends Node

const CONFIG_PATH := "user://host_config.cfg"

var server_url: String = "ws://127.0.0.1:3000/ws"
var web_port: int = 5173
var room_id: String = ""
var room_code: String = ""
var host_token: String = ""

func _ready() -> void:
	load_config()

func load_config() -> void:
	var file := ConfigFile.new()
	if file.load(CONFIG_PATH) != OK:
		return
	server_url = file.get_value("host", "server_url", server_url)
	web_port = int(file.get_value("host", "web_port", web_port))
	room_id = file.get_value("host", "room_id", "")
	room_code = file.get_value("host", "room_code", "")
	host_token = file.get_value("host", "host_token", "")

func save_config() -> void:
	var file := ConfigFile.new()
	file.set_value("host", "server_url", server_url)
	file.set_value("host", "web_port", web_port)
	file.set_value("host", "room_id", room_id)
	file.set_value("host", "room_code", room_code)
	file.set_value("host", "host_token", host_token)
	file.save(CONFIG_PATH)

func clear_session() -> void:
	room_id = ""
	room_code = ""
	host_token = ""
	save_config()

func has_saved_session() -> bool:
	return room_id != "" and host_token != ""
