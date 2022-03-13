extends Node

const VERSION = "v0.0.7WS"
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
		# $ChatRoom.visible = false
		$CardFight.visible = false
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
	
#	$ChatRoom.visible = false
	$CardFight.visible = false

## Actual game functions

func host_lobby():
	if not $Lobby/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer2/uname.text:
		sLog("Please enter a username")
		return
	
	# Deck check
	var dFile = File.new()
	dFile.open($AllCards.deck_path + $Lobby/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer2/dSelect.text + ".deck", File.READ)
	if len(parse_json(dFile.get_as_text())) == 0:
		sLog("Your deck is empty!")
		dFile.close()
		return
	dFile.close()
	
	if get_tree().network_peer:
		sLog("Cancelling existing hosting / connection attempt...")
		get_tree().network_peer = null
	
#	var peer = NetworkedMultiplayerENet.new()
#	peer.create_server(DEFAULT_PORT, MAX_PEERS)
	# Websocket networking
	var peer = WebSocketServer.new()
	peer.listen(DEFAULT_PORT, PoolStringArray(), true)
	get_tree().network_peer = peer
	
	var localip = "Unknown"
	for ip in IP.get_local_addresses():
		if ip.begins_with("192"):
			localip = ip
	
	sLog("Lobby open with ip " + localip)
	
func challenge_lobby(ip):
	if not ip:
		sLog("Please enter an IP")
		return
	if not $Lobby/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer2/uname.text:
		sLog("Please enter a username")
		return
		
	# Deck check
	var dFile = File.new()
	dFile.open($AllCards.deck_path + $Lobby/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer2/dSelect.text + ".deck", File.READ)
	if len(parse_json(dFile.get_as_text())) == 0:
		sLog("Your deck is empty!")
		dFile.close()
		return
	dFile.close()
	
	if get_tree().network_peer:
		sLog("Cancelling existing hosting / connection attempt...")
		get_tree().network_peer = null
	
	sLog("Attempting to connect to " + ip + ", please wait up to 1 minute")
	
#	var peer = NetworkedMultiplayerENet.new()
	var peer = WebSocketClient.new()
#	var err = peer.create_client(ip, DEFAULT_PORT)
	var err = peer.connect_to_url("ws://" + ip, PoolStringArray(), true)
	
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
#	$ChatRoom.visible = true
#	$ChatRoom.open()

	# Opponent is server
	opponent = 1
	
	# Load deck from file and pass to the battle handler
	var dFile = File.new()
	dFile.open($AllCards.deck_path + $Lobby/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer2/dSelect.text + ".deck", File.READ)
	var ddata = parse_json(dFile.get_as_text())
	
	$CardFight.initial_deck = ddata["cards"]
	$CardFight.side_deck_index = ddata["side_deck"]
	
	# Open the card battle window and initialise the match
	$CardFight.visible = true
	$CardFight.init_match(opponent)
	

## Remote funcs -> Server
remote func register_challenge(id: int, name: String, pfp: int):
	sLog("Registered player " + str(id) + " with name \"" + name + "\" and pfp index " + str(pfp))
	
	# Add challenger to dictionarry
	challengers[id] = name
	pids.append(id)
	
	# Update UI with challenge
	emit_signal("new_challenge", name, pfp)

	# DEBUG: Autoinitiate match if name is SERVER HOST
	if $Lobby/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer2/uname.text == "SERVER HOST":
		_accept_challenge(pids.find(id))


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
	
	# Load deck from file and pass to the battle handler
	var dFile = File.new()
	dFile.open($AllCards.deck_path + $Lobby/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer2/dSelect.text + ".deck", File.READ)
	var ddata = parse_json(dFile.get_as_text())
	
	$CardFight.initial_deck = ddata["cards"]
	$CardFight.side_deck_index = ddata["side_deck"]
	
	# Open the card battle window and initialise the match
	$CardFight.visible = true
	$CardFight.init_match(opponent)

func debug_host():
	sLog("Hosting a debug game!")

	# Set username
	$Lobby/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer2/uname.text = "SERVER HOST"

	host_lobby()

func debug_join():
	sLog("Attempting to join a local debug game!")

	# Set username
	$Lobby/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer2/uname.text = "CHALLENGER CLIENT"

	challenge_lobby("localhost:10567")

func _ready():
	randomize()
	
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
	$VersionLabel.text = VERSION
	
	if not OS.is_debug_build():
		return
	
	for option in OS.get_cmdline_args():
		if option == "listen":
			debug_host()
		if option == "join":
			debug_join()


func sLog(text):
	$Lobby/HBoxContainer/VBoxContainer/console/log.text += text + "\n"
