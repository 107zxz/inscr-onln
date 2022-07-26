extends Node

const PORT = 10567

func _ready():
	# Raw signals
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

func _player_connected():
	pass
	
func _player_disconnected():
	pass

func _connected_ok():
	pass

func _conncetion_failed():
	pass

func _server_disconnected():
	pass
