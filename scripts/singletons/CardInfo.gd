extends Node

var all_sigils = []
var all_cards = []
var working_sigils = []
var deck_path = OS.get_user_data_dir() + "/decks/"


func _enter_tree():
	read_game_info()

func read_game_info():
	var file = File.new()
	file.open("res://data/gameInfo.json", File.READ)
	var file_content = file.get_as_text()
	var content_as_object = parse_json(file_content)
	all_sigils = content_as_object["sigils"]
	all_cards = content_as_object["cards"]
	working_sigils = content_as_object["working_sigils"]


func from_name(cName):
	for card in all_cards:
		if card.name == cName:
			return card

func idx_from_name(cName):
	var idx = 0

	for card in all_cards:
		if card.name == cName:
			return idx
		idx += 1
