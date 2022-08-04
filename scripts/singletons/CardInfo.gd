extends Node

const VERSION = "0.1.2"

var all_data = {}
var ruleset = "undefined ruleset"
var all_sigils = []
var all_cards = []
var working_sigils = []

var deck_path = OS.get_user_data_dir() + "/decks/undef/"
var rules_path = OS.get_user_data_dir() + "/gameInfo.json"
var tunnellog_path = OS.get_user_data_dir() + "/lhrlog.txt"

func _enter_tree():
	read_game_info()

func from_game_info_json(content_as_object):
	all_data = content_as_object
	
	all_sigils = all_data["sigils"]
	all_cards = all_data["cards"]
	working_sigils = all_data["working_sigils"]
	
	if "ruleset" in all_data:
		ruleset = all_data.ruleset
		deck_path = OS.get_user_data_dir() + "/decks/" + ruleset + "/"

func read_game_info():
	
	# Does a downloaded ruleset exist?
	var dir = Directory.new()
	var file = File.new()
	
	if dir.file_exists(rules_path):
		file.open(rules_path, File.READ)
		print(rules_path)
	else:
		print("Downloaded rules not found! Prompting for download")
		file.open("res://data/gameInfo.json", File.READ)
		get_tree().change_scene("res://AutoUpdate.tscn")
		
	var file_content = file.get_as_text()
	var content_as_object = parse_json(file_content)
	from_game_info_json(content_as_object)

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
