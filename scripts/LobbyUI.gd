extends Control

var cnotify = preload("res://packed/cnotify.tscn")
var validpfps = ["cat", "grizzly", "stoat", "mantisgod", "packrat", "ant", "geck", "orlu", "lil boi"]
onready var selector_de: OptionButton = $HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer2/dSelect

func _on_new_challenge(name: String, portrait: int, version: String):
	var notif = cnotify.instance()
	notif.get_node("HBoxContainer/Challengername").text = name + "\n(" + version + ") wants to battle. Accept?"
	
	# Connect buttons
	notif.get_node("HBoxContainer/nbtn").connect("pressed", get_node("/root/Main"), "_decline_challenge", [$HBoxContainer/ScrollContainer/Challenges.get_position_in_parent()])
	notif.get_node("HBoxContainer/ybtn").connect("pressed", get_node("/root/Main"), "_accept_challenge", [$HBoxContainer/ScrollContainer/Challenges.get_position_in_parent()])
	notif.get_node("HBoxContainer/Challengerpfp").texture = load("res://gfx/portraits/portrait_" + $HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer2/ppSelect.get_item_text(portrait).to_lower() + ".png")
	
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
	
func _edit_deck():
	get_node("/root/Main/DeckEdit").visible = true
	get_node("/root/Main/DeckEdit").ensure_default_deck()
	get_node("/root/Main/DeckEdit").populate_deck_list()
	get_node("/root/Main/DeckEdit/HBoxContainer/VBoxContainer/DeckOptions/HBoxContainer/DeckOptions/VBoxContainer/DSelLine/DSel").select(selector_de.selected)
	get_node("/root/Main/DeckEdit").load_deck()
	

func populate_deck_list():
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
	selector_de.select(idx)
