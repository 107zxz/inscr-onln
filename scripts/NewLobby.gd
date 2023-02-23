extends Node

# Nodes
onready var themeEditor = get_node("../ThemeEditor")
onready var deckEditor = get_node("../DeckEdit")
onready var cardFight = get_node("../CardFight")
onready var hostUnameBox = $LobbyHost/Rows/Nickname/LineEdit
onready var hostLnameBox = $LobbyHost/Rows/Roomname/LineEdit
onready var joinUnameBox = $LobbyJoin/Rows/Nickname/LineEdit
onready var lobbyList: ItemList = $InLobby/Rows/PlayerList

var unreadyIcon = preload("res://gfx/extra/Off.png")
var readyIcon = preload("res://gfx/extra/On.png")

var lobby_data = {"players": {}, "spectators": []}

var rsCache: Dictionary = {}

# Godot Handlers
func _ready():

	randomize()

	# Signals
	get_tree().connect("connected_to_server", self, "_joined_game")
	get_tree().connect("connection_failed", self, "_connected_fail")
	# get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_erase_player")

	# Version
	get_node("../VersionLabel").text = CardInfo.VERSION
	get_node("../RulesetLabel").text = CardInfo.ruleset
	
	# Custom Bg
	if CardInfo.background_texture:
		$CustomBackground.texture = CardInfo.background_texture
	
	# Android
	if OS.get_name() in ["Android", "HTML5"]:
		$LobbyHost/Rows/HostType/Type.select(1)
		$LobbyHost/Rows/HostType/Type.set_item_disabled(0, true)
		$Menu/VBoxContainer/LogFolder.visible = false
		
		$LobbyHost/Rows/RoomnameInfo.visible = false
		$LobbyHost/Rows/Roomname.visible = false
	
	if OS.get_name() == "HTML5":
		$Menu/VBoxContainer/HostBtn.disabled = true
		$Menu/VBoxContainer/HostBtn.text = "Host Game (unavailable on web version)"
		

	# Select default deck by default
	for dIdx in range($InLobby/Rows/DeckOptions/Deck.get_item_count()):
		if $InLobby/Rows/DeckOptions/Deck.get_item_text(dIdx) == "default":
			$InLobby/Rows/DeckOptions/Deck.select(dIdx)
	
	yield(get_tree().create_timer(0.1), "timeout")
	
	for option in OS.get_cmdline_args():
		if option == "listen":
			debug_host()
		if option == "join":
			debug_join()

# Methods
func debug_host():
	$LobbyHost/Rows/HostType/Type.select(1)
	$LobbyHost/Rows/Nickname/LineEdit.text = "DEBUG_HOST"
	$Blocker.visible = true

	_on_Host_pressed()
#	_on_LobbyReady_pressed()

func debug_join():

	yield(get_tree().create_timer(0.1), "timeout")

	$LobbyJoin/Rows/Address/IPInput.text = "127.0.0.1"
	$LobbyJoin/Rows/Nickname/LineEdit.text = "DEBUG_CLIENT"
	$LobbyJoin/Rows/HostType/LType.select(1)

	_on_Join_pressed()
#	yield(get_tree().create_timer(0.2), "timeout")
#	_on_LobbyReady_pressed()

func errorBox(message, show_dlbtn: bool = false):
	$ErrorBox/Contents/Label.text = message
	$ErrorBox.visible = true
	$ErrorBox/Contents/ErrorDL.visible = show_dlbtn
	
func populate_deck_list():
	
	print("Populating lobby deck list")
	
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
		lobbyList.add_item(lobby_data.players[player].name + " (" + str(lobby_data.players[player].wins) + " wins)", readyIcon if lobby_data.players[player].ready else unreadyIcon)

	$InLobby/Rows/Spectators.text = str(len(lobby_data.spectators)) + " Spectators"
	
	$InLobby/Rows/LCode.text = ("IP: " if lobby_data.is_ip else "Lobby Code: ") + lobby_data.code

func count_victory():
	lobby_data.players[get_tree().get_network_unique_id()].wins += 1
	cardFight.get_node("PlayerInfo/MyInfo/Username").text = lobby_data.players[get_tree().get_network_unique_id()].name + " (" + str(lobby_data.players[get_tree().get_network_unique_id()].wins) + " wins)"

func count_loss(opponent):
	lobby_data.players[opponent].wins += 1
	cardFight.get_node("PlayerInfo/TheirInfo/Username").text = lobby_data.players[opponent].name + " (" + str(lobby_data.players[opponent].wins) + " wins)"

func init_fight(go_first: int):
	print("Morbin time")

	lobbyList.set_item_icon(0, unreadyIcon)
	lobbyList.set_item_icon(1, unreadyIcon)

	# Identify players
	var myId = get_tree().get_network_unique_id()
	var oppId = -1
	
	# Spectator oppid
	if not myId in lobby_data.players:
		oppId = go_first

	for player in lobby_data.players:

		lobby_data.players[player].ready = false

		if player != myId:
			oppId = player
		
		# Sepc testing
		if player != go_first and not myId in lobby_data.players:
			myId = player
	

	# Pass deck to CardFight
	if myId in lobby_data.players:
		deckEditor.ensure_default_deck()
		deckEditor.populate_deck_list()
		deckEditor.get_node("HBoxContainer/VBoxContainer/DeckOptions/HBoxContainer/DeckOptions/VBoxContainer/DSelLine/DSel").select($InLobby/Rows/DeckOptions/Deck.selected)
		deckEditor.load_deck()
		var ddata = deckEditor.get_deck_object()

		cardFight.initial_deck = ddata.cards
		
		if CardInfo.side_decks:

			cardFight.side_deck_cards = []

			match CardInfo.side_decks[ddata.side_deck].type:
				"single":
					cardFight.side_deck_key = ddata.side_deck
				"single_cat":
					cardFight.side_deck_key = [ddata.side_deck, ddata.side_deck_cat]
				"draft":
					cardFight.side_deck_key = ddata.side_deck
					cardFight.side_deck_cards = ddata.side_deck_cards
		else:
			cardFight.side_deck_key = null
		
		if "characters" in CardInfo and CardInfo.characters:
			cardFight.chardata = CardInfo.characters[ddata.character]
			cardFight.get_node("PlayerInfo/MyInfo/pfp").draw(ddata["character"])
		else:
			# panic
			assert(false)
		
	cardFight.get_node("PlayerInfo/MyInfo/Username").text = lobby_data.players[myId].name + " (" + str(lobby_data.players[myId].wins) + " wins)"
	cardFight.get_node("PlayerInfo/TheirInfo/Username").text = lobby_data.players[oppId].name + " (" + str(lobby_data.players[oppId].wins) + " wins)"
	
	cardFight.get_node("PlayerInfo/TheirInfo/pfp").draw(lobby_data.players[oppId].character)

	cardFight.visible = true
	cardFight.init_match(oppId, go_first == myId)

# UI Callbacks
func _on_DiscordBtn_pressed():
	OS.shell_open("https://discord.gg/wXS2FpJpCt")

func _on_ThemeEditorBtn_pressed():
	themeEditor.visible = not themeEditor.visible

func _on_DeckEditorBtn_pressed():
	deckEditor.visible = true

	deckEditor.visible = true
	deckEditor.ensure_default_deck()
	deckEditor.populate_deck_list()
	deckEditor.get_node("HBoxContainer/VBoxContainer/DeckOptions/HBoxContainer/DeckOptions/VBoxContainer/DSelLine/DSel").select($InLobby/Rows/DeckOptions/Deck.selected)
	deckEditor.load_deck()

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
		
	# Check lobby name
	
	if $LobbyHost/Rows/HostType/Type.selected == 0:

		var regex = RegEx.new()
#		regex.compile("[ !$%^&*()_+|~=`{}\[\]:";'<>?,.\/]")
		regex.compile("[^a-z0-9\\-]")

		var lobbyName = hostLnameBox.text
		if regex.search(lobbyName) != null or len(lobbyName) < 5:
			print("Invalid lobby name")
			return
			
	print("Regex valid")
	
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
		lobby_data.players = {1: {"name": hostUnameBox.text, "ready": false, "pfp": "Grizzly", "wins": 0}}
	else:
		lobby_data.spectators = [1]
	
	if $LobbyHost/Rows/HostType/Type.selected == 0:
		$LoadingScreen.visible = true		
		$LoadingScreen/AnimationPlayer.play("progress")
		# Open a tunnel
		TunnelHandler.start_tunnel(hostLnameBox.text)
		TunnelHandler.connect("received_output", self, "_on_tunnel_output")
		TunnelHandler.connect("received_error", self, "_on_tunnel_error")
#		TunnelHandler.connect("process_ended", self, "_on_host_timeout")
	else:
		$InLobby.visible = true

		$InLobby/Rows/LCode.text = "IP: N/A"
		lobby_data.code = "N/A"
		for ip in IP.get_local_addresses():
			if ip.begins_with("192"):
				$InLobby/Rows/LCode.text = "IP: " + ip
				lobby_data.code = ip
				break
				
		lobby_data.is_ip = true

		update_lobby()


func _on_LobbyQuit_pressed():
	TunnelHandler.kill_tunnel()
	$InLobby.visible = false
	$Blocker.visible = false

	NetworkManager.kill()

func _on_LogFolder_pressed():
	if OS.get_name() in ["Android", "HTML5"]:
		errorBox("Your game directory is: " + CardInfo.data_path)
		return
	OS.shell_open("file://" + OS.get_user_data_dir())

func _on_ErrorOk_pressed():
	$ErrorBox.visible = false
	if $SpecialBlocker.visible:
		$SpecialBlocker.visible = false
	else:
		$Blocker.visible = false


func _on_Join_pressed():

	# Check params
	var url = $LobbyJoin/Rows/Address/IPInput.text
	
	if joinUnameBox.text == "":
		return

	if url == "":
		return

	if $LobbyJoin/Rows/HostType/LType.selected == 0:
		url = "wss://" + url + ".loca.lt"
	else:
		if ":" in url:
			url = "ws://" + url
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
	
	# handle deck
	deckEditor.ensure_default_deck()
	deckEditor.populate_deck_list()
	deckEditor.get_node("HBoxContainer/VBoxContainer/DeckOptions/HBoxContainer/DeckOptions/VBoxContainer/DSelLine/DSel").select($InLobby/Rows/DeckOptions/Deck.selected)
	deckEditor.load_deck()

	var index = 0
	
	for key in lobby_data.players:
		if key == get_tree().get_network_unique_id():
			
			var do = deckEditor.get_deck_object()
			
			if not lobby_data.players[key].ready:
				
				if len(do["cards"]) < CardInfo.all_data.deck_size_min and not "listen" in OS.get_cmdline_args() and not "join" in OS.get_cmdline_args():
					$SpecialBlocker.visible = true
					errorBox("The currently selected deck is too small!\nMust be at least " + str(CardInfo.all_data.deck_size_min) + " cards!")
					return
				
				if "side_deck_cards" in do and len(do.side_deck_cards) == 0:
					$SpecialBlocker.visible = true
					errorBox("Your side deck is empty!")
					return
			
			lobby_data.players[key].ready = not lobby_data.players[key].ready
			lobby_data.players[key].character = do.character
			lobbyList.set_item_icon(index, readyIcon if lobby_data.players[key].ready else unreadyIcon)
			rpc("_player_status", lobby_data.players[key])
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
	print(lobby_data.players)
	var go_first = lobby_data.players.keys()[randi() % lobby_data.players.size()]
	
	print("Chosen player to go first is : ", go_first)
	
	rpc("_start_match", go_first)
	init_fight(go_first)

func _on_SelectVersionBtn_pressed():
	get_tree().change_scene("res://packed/RulesetPickerProto.tscn")

func _on_Kick_pressed():
	rpc_id(lobby_data.players.keys()[lobbyList.get_selected_items()[0]], "_rejected", "Kicked by lobby host")

# Network callbacks
func _on_tunnel_output(code):
	TunnelHandler.disconnect("received_output", self, "_on_tunnel_output")
	TunnelHandler.disconnect("received_error", self, "_on_tunnel_error")
	
	$LoadingScreen.visible = false
	$InLobby.visible = true
#		$InLobby/Rows/LCode.text = "Lobby Code: " + code
	
	lobby_data.code = code
	lobby_data.is_ip = false
	
	update_lobby()
	
func _on_tunnel_error(err):
	errorBox(err)
	$LoadingScreen.visible = false
	TunnelHandler.disconnect("received_output", self, "_on_tunnel_output")
	TunnelHandler.disconnect("received_error", self, "_on_tunnel_error")

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
				"ready": false,
				"pfp": "Grizzly",
				"wins": 0,
				"ruleset": CardInfo.all_data.hash(),
				"version": CardInfo.VERSION
#				"version": "0.0.69"
			}
		)
		$InLobby/Rows/DeckOptions.visible = true
		$InLobby/Rows/ProfilePic.visible = true
		$InLobby/Rows/Buttons/LobbyReady.visible = true

func _connected_fail():
	var url = $LobbyJoin/Rows/Address/IPInput.text
	
	if $LobbyJoin/Rows/HostType/LType.selected == 0:
		url = "wss://" + url + ".loca.lt"
	else:
		url = "ws://" + url + ":10567"
	
	$LoadingScreen.visible = false
	$InLobby.visible = false
	cardFight.visible = false
	cardFight.get_node("MoonFight/AnimationPlayer").play("RESET")	
	errorBox("Connection to url: " + url + " failed!")

func _player_connected():
	pass

# Remotes
remote func _register_player(player_data: Dictionary):

	# Reject if 2 players already in lobby
	if len(lobby_data.players.keys()) == 2 and get_tree().is_network_server():
		rpc_id(get_tree().get_rpc_sender_id(), "_rejected", "Lobby is full, you may still join as a spectator")
		return
	
	# Reject if running a different game version or ruleset
	if player_data["version"] != CardInfo.VERSION:
		rpc_id(get_tree().get_rpc_sender_id(), "_ruleset_rejected", CardInfo.all_data)
		return
	
	
	if player_data["ruleset"] != CardInfo.all_data.hash():
#		print(CardInfo.all_data.hash(), " : ", player_data["ruleset"])
		rpc_id(get_tree().get_rpc_sender_id(), "_ruleset_rejected", CardInfo.all_data)
#		rpc_id(get_tree().get_rpc_sender_id(), "_rejected", "Your opponent is running a different ruleset to you (\"" + CardInfo.ruleset + "\").\nPlease note that changing the name of your ruleset is not a valid solution.")
		return
	
	
		
	lobby_data.players[get_tree().get_rpc_sender_id()] = player_data
	update_lobby()

	# Send info to all players
	rpc("_recieve_lobby_info", lobby_data)

remote func _register_spectator():
	
	# Don't allow spectating if in game
	if cardFight.visible:
		rpc_id(get_tree().get_rpc_sender_id(), "_rejected", "Match already in progress")
		return
	
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

remote func _ruleset_rejected(rs_dat: Dictionary):
	$LoadingScreen.visible = false
	$LobbyJoin.visible = false
	$InLobby.visible = false
	errorBox("Your opponent is running ruleset \"" + rs_dat.ruleset + "\", download it?", true)
	
	rsCache = rs_dat
	
	NetworkManager.kill()

func _on_ErrorDL_pressed():
	print("DOWNLOADING RULESET: \n", rsCache)
	CardInfo.rs_to_apply = rsCache
	get_tree().change_scene("res://packed/RulesetPickerProto.tscn")

remote func _erase_player(player_id):

	if player_id in lobby_data.spectators:
		lobby_data.spectators.erase(player_id)

	if player_id in lobby_data.players:
		lobby_data.players.erase(player_id)
		cardFight.visible = false
		cardFight.get_node("MoonFight/AnimationPlayer").play("RESET")

	update_lobby()
	
#	if get_tree().get_network_unique_id() in lobby_data.players and lobby_data.players[get_tree().get_network_unique_id()].name == "DEBUG_HOST":
#		# Fun fact: removing this line makes the game crash
#		yield(get_tree().create_timer(0.1), "timeout")
#
#		_on_LobbyQuit_pressed()

remote func _recieve_lobby_info(new_ld: Dictionary):

	lobby_data = new_ld
	update_lobby()

remote func _player_status(status: Dictionary):
	lobby_data.players[get_tree().get_rpc_sender_id()] = status

	update_lobby()

	# Start the game if both players are ready
	if not get_tree().is_network_server():
		return

	for player in lobby_data.players:
		if not lobby_data.players[player].ready:
			return

	# Turn order
	print(lobby_data.players)
	var go_first = lobby_data.players.keys()[randi() % lobby_data.players.size()]
	
	print("Chosen player to go first is : ", go_first)
	
	rpc("_start_match", go_first)
	init_fight(go_first)
	
remote func _start_match(go_first: int):
	init_fight(go_first)

# Android, move all windows up when virtual keyboard appears
func _LineEdit_focused():
	if OS.get_name() == "Android":
		$LobbyHost.rect_position.y -= 130
		$LobbyJoin.rect_position.y -= 130

func _LineEdit_unfocused():
	if OS.get_name() == "Android":
		$LobbyHost.rect_position.y += 130
		$LobbyJoin.rect_position.y += 130


func _on_HostType_selected(index):
	$LobbyHost/Rows/RoomnameInfo.visible = index == 0
	$LobbyHost/Rows/Roomname.visible = index == 0

