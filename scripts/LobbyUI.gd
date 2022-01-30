extends Control

var cnotify = preload("res://packed/cnotify.tscn")
var validpfps = ["cat", "grizzly", "stoat", "mantisgod", "packrat"]

func _on_new_challenge(name: String, portrait: int):
	var notif = cnotify.instance()
	notif.get_node("HBoxContainer/Challengername").text = name + " wants to battle you. Accept?"
	
	# Connect buttons
	notif.get_node("HBoxContainer/nbtn").connect("pressed", get_node("/root/Main"), "_decline_challenge", [$HBoxContainer/ScrollContainer/Challenges.get_position_in_parent()])
	notif.get_node("HBoxContainer/ybtn").connect("pressed", get_node("/root/Main"), "_accept_challenge", [$HBoxContainer/ScrollContainer/Challenges.get_position_in_parent()])
	notif.get_node("HBoxContainer/Challengerpfp").texture = load("res://gfx/pfp/portrait_" + $HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer2/ppSelect.get_item_text(portrait).to_lower() + ".png")
	
	$HBoxContainer/ScrollContainer/Challenges.add_child(notif)

func _remove_challenge(idx):
	$HBoxContainer/ScrollContainer/Challenges.get_child(idx).queue_free()

func _join_game():
	get_node("/root/Main").challenge_lobby($HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/targetIP.text)

func _ready():
	# Populate profile picture selector
	var selector = $HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer2/ppSelect
	
	for pfp in validpfps:
		selector.add_item(pfp)
