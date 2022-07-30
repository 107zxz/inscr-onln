extends Node

# Nodes
onready var themeEditor = get_node("../ThemeEditor")
onready var deckEditor = get_node("../DeckEdit")
onready var cardFight = get_node("../CardFight")
onready var hostUnameBox = $LobbyHost/Rows/Nickname/LineEdit
onready var joinUnameBox = $LobbyJoin/Rows/Nickname/LineEdit
onready var lobbyList: ItemList = $InLobby/Rows/PlayerList

var unreadyIcon = preload("res://gfx/sigils/Orange Mox.png")
var readyIcon = preload("res://gfx/sigils/Green Mox.png")

var lobby_data = {"players": {}, "spectators": []}

# Godot Handlers
func _ready():

	randomize()

	# Signals
	get_tree().connect("connected_to_server", self, "_joined_game")
	get_tree().connect("connection_failed", self, "_connected_fail")
	# get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_erase_player")

	# Register profile pictures
	var pfpsel = $InLobby/Rows/ProfilePic/Pic

	var dTest = Directory.new()
	dTest.open("res://gfx/portraits")
	dTest.list_dir_begin()
	var fName = dTest.get_next()
	while fName != "":
		if not dTest.current_is_dir() and fName.ends_with(".png"):
			pfpsel.add_item(fName.split(".png")[0])
		fName = dTest.get_next()

# Methods
func errorBox(message):
	$ErrorBox/Contents/Label.text = message
	$ErrorBox.visible = true
	
func populate_deck_list():
	var selector_de = $InLobby/Rows/DeckOptions/Deck

	selector_de.clear()
	
	var dTest = Directory.new()
	dTest.open(CardInfo.deck_path)
	dTest.list_dir_begin()
	var fName = dTest.get_next()
	while fName != "":
		if not dTest.current_is_dir() and fName.ends_with(".deck"):
			selector_de.add_item(fName.split(".deck")[0])
		fName = dTest.get_next()

func select_deck(idx):
	$InLobby/Rows/DeckOptions/Deck.select(idx)

func update_lobby():
	lobbyList.clear()

	for player in lobby_data.players:
		lobbyList.add_item(lobby_data.players[player].name, readyIcon if lobby_data.players[player].ready else unreadyIcon)

	$InLobby/Rows/Spectators.text = str(len(lobby_data.spectators)) + " Spectators"
	
	$InLobby/Rows/LCode.text = ("IP: " if lobby_data.is_ip else "Lobby Code: ") + lobby_data.code
	
func init_fight(go_first: bool):
	print("Morbin time")

	# Identify players
	var myId = get_tree().get_network_unique_id()
	var oppId = -1

	for player in lobby_data.players:
		if player != myId:
			oppId = player
	
	# Pass deck to CardFight
	deckEditor.load_deck()
	var ddata = deckEditor.get_deck_object()

	cardFight.initial_deck = ddata.cards
	cardFight.side_deck_index = ddata.side_deck
	if "vessel_type" in ddata:
		cardFight.side_deck = [ddata.vessel_type]
	
	# Usernames and profile pictures
	cardFight.get_node("PlayerInfo/MyInfo/Username").text = lobby_data.players[myId].name
	cardFight.get_node("PlayerInfo/TheirInfo/Username").text = lobby_data.players[oppId].name

	cardFight.visible = true
	cardFight.init_match(oppId, go_first)

# UI Callbacks
func _on_DiscordBtn_pressed():
	OS.shell_open("https://discord.gg/wXS2FpJpCt")

func _on_ThemeEditorBtn_pressed():
	themeEditor.visible = not themeEditor.visible

func _on_DeckEditorBtn_pressed():
	deckEditor.visible = true

	get_node("/root/Main/DeckEdit").visible = true
	get_node("/root/Main/DeckEdit").ensure_default_deck()
	get_node("/root/Main/DeckEdit").populate_deck_list()
	get_node("/root/Main/DeckEdit/HBoxContainer/VBoxContainer/DeckOptions/HBoxContainer/DeckOptions/VBoxContainer/DSelLine/DSel").select($InLobby/Rows/DeckOptions/Deck.selected)
	get_node("/root/Main/DeckEdit").load_deck()
func _on_HostBtn_pressed():
	$LobbyHost.visible = true
	$Blocker.visible = true

func _on_JoinBtn_pressed():
	$LobbyJoin.visible = true
	$Blocker.visible = true

func _on_CancelHost_pressed():
	$LobbyHost.visible = false
	$Blocker.visible = false

func _on_CancelJoin_pressed():
	$LobbyJoin.visible = false
	$Blocker.visible = false


func _on_Host_pressed():

	lobby_data = {"players": {}, "spectators": []}

	if hostUnameBox.text.length() == 0:
		return
	
	$LobbyHost.visible = false
	lobbyList.clear()

	$InLobby/Rows/DeckOptions.visible = true
	$InLobby/Rows/ProfilePic.visible = true
	$InLobby/Rows/Buttons/LobbyReady.visible = true

	# Only host can see kick button
	$InLobby/Rows/Buttons2.visible = true

	# Host Lobby
	NetworkManager.host_lobby()
	
	# only add myself to the list if not spectating
	if not $LobbyHost/Rows/Spectating/CheckBox.pressed:
		lobby_data.players = {1: {"name": hostUnameBox.text, "ready": false}}
	else:
		lobby_data.spectators = [1]
	
	if $LobbyHost/Rows/HostType/Type.selected == 0:
		$LoadingScreen.visible = true		
		$LoadingScreen/AnimationPlayer.play("progress")
		# Open a tunnel
		TunnelHandler.start_tunnel()
		TunnelHandler.connect("recieved_output", self, "_on_tunnel_output")
		TunnelHandler.connect("process_ended", self, "_on_host_timeout")
	else:
		$InLobby.visible = true

		$InLobby/Rows/LCode.text = "IP: N/A"
		for ip in IP.get_local_addresses():
			if ip.begins_with("192"):
				$InLobby/Rows/LCode.text = "IP: " + ip

				lobby_data.code = ip
				lobby_data.is_ip = true
				break

		update_lobby()


func _on_LobbyQuit_pressed():
	TunnelHandler.kill_tunnel()
	$InLobby.visible = false
	$Blocker.visible = false

	NetworkManager.kill()

func _on_LogFolder_pressed():
	OS.shell_open("file://" + OS.get_user_data_dir() + "/logs/")

func _on_ErrorOk_pressed():
	$ErrorBox.visible = false
	$Blocker.visible = false


func _on_Join_pressed():

	# Check params
	var url = $LobbyJoin/Rows/Address/IPInput.text
	
	if joinUnameBox.text == "":
		return

	if url == "":
		return

	if $LobbyJoin/Rows/HostType/LType.selected == 0:
		url = "ws://" + url + ".lhrtunnel.link"	
	else:
		url = "ws://" + url + ":10567"

	NetworkManager.join_lobby(url)

	$LoadingScreen.visible = true
	$LoadingScreen/AnimationPlayer.play("progressjoin")
	$LobbyJoin.visible = false
	$Blocker.visible = true

func _on_PasteButton_pressed():
	$LobbyJoin/Rows/Address/IPInput.text = OS.clipboard

func _on_CopyCode_pressed():
	OS.clipboard = lobby_data.code

func _on_LobbyReady_pressed():
	var index = 0
	
	for key in lobby_data.players:
		if key == get_tree().get_network_unique_id():
			lobby_data.players[key].ready = not lobby_data.players[key].ready
			lobbyList.set_item_icon(index, readyIcon if lobby_data.players[key].ready else unreadyIcon)
			rpc("_player_ready", lobby_data.players[key].ready)
			break
		index = index + 1

	# Start the game if both players are ready
	if not get_tree().is_network_server():
		return

	# Are there 2 players?
	if len(lobby_data.players.keys()) < 2:
		return

	for player in lobby_data.players:
		if not lobby_data.players[player].ready:
			return

	# Turn order
	var go_first = randf() < 0.5

	rpc("_start_match", not go_first)
	init_fight(go_first)

# Network callbacks
func _on_tunnel_output(line):
	if "tunneled with tls termination" in line:
		TunnelHandler.disconnect("recieved_output", self, "_on_tunnel_output")
		
		var code = line.split(".")[0]
		
		$LoadingScreen.visible = false
		$InLobby.visible = true
#		$InLobby/Rows/LCode.text = "Lobby Code: " + code
		
		lobby_data.code = code
		lobby_data.is_ip = false
		
		update_lobby()

		TunnelHandler.disconnect("process_ended", self, "_on_host_timeout")
		
func _on_host_timeout():
	$LoadingScreen.visible = false
	errorBox("Failed to connect to localhost.run.\nAre you connected to the internet?")
	
	TunnelHandler.disconnect("recieved_output", self, "_on_tunnel_output")
	TunnelHandler.disconnect("process_ended", self, "_on_host_timeout")

	NetworkManager.kill()

func _joined_game():
	$LoadingScreen.visible = false
	$InLobby.visible = true
	
	# Only host can see kick button
	$InLobby/Rows/Buttons2.visible = false
	
	if $LobbyJoin/Rows/Spectate/CheckBox.pressed:
		rpc("_register_spectator")
		$InLobby/Rows/DeckOptions.visible = false
		$InLobby/Rows/ProfilePic.visible = false
		$InLobby/Rows/Buttons/LobbyReady.visible = false
	else:
		rpc("_register_player", 
			{
				"name": joinUnameBox.text,
				"ready": false
			}
		)
		$InLobby/Rows/DeckOptions.visible = true
		$InLobby/Rows/ProfilePic.visible = true
		$InLobby/Rows/Buttons/LobbyReady.visible = true

func _connected_fail():
	var url = $LobbyJoin/Rows/Address/IPInput.text
	
	if $LobbyJoin/Rows/HostType/LType.selected == 0:
		url = "ws://" + url + ".lhrtunnel.link"	
	else:
		url = "ws://" + url + ":10567"
	
	$LoadingScreen.visible = false
	$InLobby.visible = false
	errorBox("Connection to url: " + url + " failed!")

func _player_connected():
	pass

# Remotes
remote func _register_player(player_data: Dictionary):

	if len(lobby_data.players.keys()) == 2 and get_tree().is_network_server():
		rpc_id(get_tree().get_rpc_sender_id(), "_rejected", "Lobby is full, you may still join as a spectator")
		return
	
	lobby_data.players[get_tree().get_rpc_sender_id()] = player_data
	update_lobby()

	# Send info to all players
	rpc("_recieve_lobby_info", lobby_data)

remote func _register_spectator():
	if not get_tree().get_rpc_sender_id() in lobby_data.spectators:
		lobby_data.spectators.append(get_tree().get_rpc_sender_id())
	
	# Send info to all players
	rpc("_recieve_lobby_info", lobby_data)

remote func _rejected(reason: String):
	$LoadingScreen.visible = false
	$LobbyJoin.visible = false
	$InLobby.visible = false
	errorBox("Disconnected by opponent:\nReason: " + reason)

	NetworkManager.kill()


remote func _erase_player(player_id):

	if player_id in lobby_data.spectators:
		lobby_data.spectators.erase(player_id)

	if player_id in lobby_data.players:
		lobby_data.players.erase(player_id)

	update_lobby()

remote func _recieve_lobby_info(new_ld: Dictionary):

	lobby_data = new_ld
	update_lobby()

remote func _player_ready(ready: bool):
	lobby_data.players[get_tree().get_rpc_sender_id()].ready = ready

	update_lobby()

	# Start the game if both players are ready
	if not get_tree().is_network_server():
		return

	for player in lobby_data.players:
		if not lobby_data.players[player].ready:
			return

	var go_first = randf() < 0.5

	rpc("_start_match", not go_first)
	init_fight(go_first)
	
remote func _start_match(go_first: bool):
	init_fight(go_first)
