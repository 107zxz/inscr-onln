extends Node

const PORT = 10567

func _ready():
	# Raw signals
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

func _player_connected(id: int):
	print("Player connected with id " + str(id))
	
func _player_disconnected(id: int):
	print("Player disconnected with id " + str(id))

func _connected_ok():
	print("Connected Successfully")

func _connected_fail():
	print("Connection Failed")

func _server_disconnected():
	print("Connection to server lost")

func host_lobby() -> int:
	var peer = WebSocketServer.new()
	var err = peer.listen(PORT, PoolStringArray(), true)
	
	if err:
		return err
	else:
		get_tree().network_peer = peer
		return 0

func join_lobby(url: String) -> int:

	print("Connecting to lobby with url: " + url)

	var peer = WebSocketClient.new()
	var err = peer.connect_to_url(url, PoolStringArray(), true)
	
	if err:
		return err
	else:
		get_tree().network_peer = peer
		return 0

func kill():
	if get_tree().network_peer:
		var _nop = get_tree().network_peer.stop() if get_tree().is_network_server() else get_tree().network_peer.disconnect_from_host()
		get_tree().network_peer = null
