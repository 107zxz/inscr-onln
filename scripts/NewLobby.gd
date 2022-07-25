extends Node

onready var themeEditor = get_node("../ThemeEditor")
onready var deckEditor = get_node("../DeckEdit")

func _on_DiscordBtn_pressed():
	OS.shell_open("https://discord.gg/wXS2FpJpCt")

func _on_ThemeEditorBtn_pressed():
	themeEditor.visible = not themeEditor.visible

func _on_DeckEditorBtn_pressed():
	deckEditor.visible = true

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
	if $LobbyHost/Rows/Nickname/LineEdit.text.length() == 0:
		return
	
	$LobbyHost.visible = false
	$LoadingScreen.visible = true
	$LoadingScreen/AnimationPlayer.play("progress")
	
	# Open a tunnel
	TunnelHandler.start_tunnel()
	TunnelHandler.connect("recieved_output", self, "_on_tunnel_output")

func _on_tunnel_output(line):
	if "tunneled with tls termination" in line:
		TunnelHandler.disconnect("recieved_output", self, "_on_tunnel_output")
		
		var code = line.split(".")[0]
		
		$LoadingScreen.visible = false
		$InLobby.visible = true
		$InLobby/Rows/LCode.text = "Lobby Code: " + code
		
func _on_LobbyQuit_pressed():
	TunnelHandler.kill_tunnel()
	$InLobby.visible = false
	$Blocker.visible = false
