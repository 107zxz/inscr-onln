# Based on https://github.com/godotengine/godot-demo-projects/blob/master/networking/multiplayer_bomber/gamestate.gd

extends Node

const DEFAULT_PORT = 10567

const MAX_PEERS = 8

# Current challengers
var challengers = {}
var pids = []

# Current opponent, set during an actual game
var opponent = -1

# Lobby signals
signal new_challenge(name, portrait)
signal remove_challenge(name)
signal game_ended()
signal kicked_from_game()
signal connection_failed()

## SceneTree Callbacks
func _player_connected(id):
	if get_tree().is_network_server():
		sLog("Player " + str(id) + " connected, requesting their info")
		
		# Inform the player we are waiting
		rpc_id(id, "challenge_requested", $Lobby/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer2/uname.text)

func _player_disconnected(id):
	sLog("Player " + str(id) + " disconnected")
	
	# Remove opponent from challenges
	emit_signal("remove_challenge", pids.find(id))
	
	# Wipe opponent from challengers dict
	challengers.erase(id)
	pids.erase(id)
	
	# Is game in progress?
	if opponent != -1:
		$ChatRoom.visible = false
		opponent = -1

func _connected_ok():
	# Connected to server
	sLog("connected successfully")

func _connected_fail():
	sLog("connection failed!")
	emit_signal("connection_failed")
	get_tree().network_peer = null
	
func _server_disconnected():
	sLog("Server disconnected!")
	get_tree().network_peer = null	
	
	$ChatRoom.visible = false

## Actual game functions

func host_lobby():
	if get_tree().network_peer:
		sLog("Already hosting a game")
		return
	
	if not $Lobby/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer2/uname.text:
		sLog("Please enter a username")
		return
	
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().network_peer = peer
	
	sLog("Lobby open with ip " + IP.get_local_addresses()[0])
	
func challenge_lobby(ip):
	if not ip:
		sLog("Please enter an IP")
		return
	if not $Lobby/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer2/uname.text:
		sLog("Please enter a username")
		return
	
	var peer = NetworkedMultiplayerENet.new()
	var err = peer.create_client(ip, DEFAULT_PORT)
	
	if not err:
		get_tree().network_peer = peer
	else:
		sLog("Error connecting to server! Error " + str(err))

func chat_kick(pid):
	# Inform opponent they are kicked
	rpc_id(pid, "kicked_from_chat")
	
	# Kick opponent from game
	get_tree().network_peer.disconnect_peer(pid)

## Remote funcs -> Client
remote func challenge_requested(uname: String):
	# Save server's username
	challengers[1] = uname
	
	sLog("Registering with server")
	rpc_id(1, "register_challenge", get_tree().network_peer.get_unique_id(), $Lobby/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer2/uname.text, $Lobby/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer2/ppSelect.selected)

remote func challenge_refused():
	sLog("Challenge refused!")

remote func kicked_from_chat():
	sLog("Challenge refused!")
	emit_signal("kicked_from_game")

remote func server_accepted_challenge():
	sLog("Challenge accepted by server!")
	$ChatRoom.visible = true

## Remote funcs -> Server
remote func register_challenge(id: int, name: String, pfp: int):
	sLog("Registered player " + str(id) + " with name \"" + name + "\" and pfp index " + str(pfp))
	
	# Add challenger to dictionarry
	challengers[id] = name
	pids.append(id)
	
	# Update UI with challenge
	emit_signal("new_challenge", name, pfp)


## UI funcs -> Server
func _decline_challenge(index):
	# Inform opponent they are kicked
	rpc_id(pids[index], "challenge_refused")
	
	# Kick opponent from game
	get_tree().network_peer.disconnect_peer(pids[index])	

func _accept_challenge(index):
	# Inform opponent their request was accepted
	rpc_id(pids[index], "server_accepted_challenge")
	
	# Set opponent
	opponent = pids[index]
	
	# Open the chat window
	$ChatRoom.visible = true
	

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
#	for option in OS.get_cmdline_args():
#		if option == "listen":
#			host_lobby()
#		if option == "join":
#			challenge_lobby("localhost")


func sLog(text):
	$Lobby/HBoxContainer/VBoxContainer/console/log.text += text + "\n"
