extends Node

var all_sigils = []
var all_cards = []
var working_sigils = []
var deck_path = "decks/"

func _enter_tree():
	read_game_info()
	
	if OS.get_name() == "OSX":
		deck_path = "user://decks/"

func read_game_info():
	var file = File.new()
	file.open("res://data/gameInfo.json", File.READ)
	var file_content = file.get_as_text()
	var content_as_object = parse_json(file_content)
	all_sigils = content_as_object["sigils"]
	all_cards = content_as_object["cards"]
	working_sigils = content_as_object["working_sigils"]
