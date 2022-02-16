extends Node

var all_sigils = []
var all_cards = []

func _ready():
	read_game_info()

func read_game_info():
	var file = File.new()
	file.open("res://data/gameInfo.json", File.READ)
	var file_content = file.get_as_text()
	var content_as_object = parse_json(file_content)
	all_sigils = content_as_object["sigils"]
	all_cards = content_as_object["cards"]
