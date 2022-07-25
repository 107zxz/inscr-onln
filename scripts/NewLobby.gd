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

func _on_CancelHost_pressed():
	$LobbyHost.visible = false
	$Blocker.visible = false
