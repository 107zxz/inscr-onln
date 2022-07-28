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
	
	if $LobbyHost/Rows/HostType/Type.selected == 0:
		# Open a tunnel
		TunnelHandler.start_tunnel()
		TunnelHandler.connect("recieved_output", self, "_on_tunnel_output")
		TunnelHandler.connect("process_ended", self, "_on_host_timeout")
	
	# Host Lobby
	NetworkManager.host_lobby("107zxz")
	

func _on_host_timeout():
	$LoadingScreen.visible = false
	errorBox("Failed to connect to localhost.run.\nAre you connected to the internet?")
	
	TunnelHandler.disconnect("recieved_output", self, "_on_tunnel_output")
	TunnelHandler.disconnect("process_ended", self, "_on_host_timeout")

func _on_tunnel_output(line):
	if "tunneled with tls termination" in line:
		TunnelHandler.disconnect("recieved_output", self, "_on_tunnel_output")
		
		var code = line.split(".")[0]
		
		$LoadingScreen.visible = false
		$InLobby.visible = true
		$InLobby/Rows/LCode.text = "Lobby Code: " + code
		TunnelHandler.disconnect("process_ended", self, "_on_host_timeout")
		
		
func _on_LobbyQuit_pressed():
	TunnelHandler.kill_tunnel()
	$InLobby.visible = false
	$Blocker.visible = false

func _on_LogFolder_pressed():
	OS.shell_open("file://" + OS.get_user_data_dir() + "/logs/")

func _on_ErrorOk_pressed():
	$ErrorBox.visible = false
	$Blocker.visible = false

func errorBox(message):
	$ErrorBox/Contents/Label.text = message
	$ErrorBox.visible = true
