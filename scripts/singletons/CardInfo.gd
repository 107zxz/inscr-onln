extends Node

const VERSION = "v0.2.2"

var all_data = {}
var ruleset = "undefined ruleset"
var all_sigils = []
var all_cards = []
var working_sigils = []

var custom_portraits = {}

var side_decks = {}

#var data_path = OS.get_user_data_dir() # if OS.get_name() != "Android" else "/sdcard/IMF/"

var data_path = "user:/"

var deck_path = data_path + "/decks/"
var deck_backup_path = data_path + "/decks/undef/"
var rules_path = data_path + "/gameInfo.json"
var theme_path = data_path + "/theme.json"
var options_path = data_path + "/options.json"
var tunnellog_path = data_path + "/lhrlog.txt"
var custom_portrait_path = data_path + "/custom_portraits/"
var custom_icon_path = data_path + "/custom_sigil_icons/"
var portrait_override_path = data_path + "/portrait_overrides/"
var icon_override_path = data_path + "/sigil_icon_overrides/"
var replay_path = data_path + "/replays/"

# CB
var background_texture = null

func _enter_tree():
	
	if OS.get_name() == "Android":
		var d = Directory.new()
		if not d.dir_exists(data_path):
			d.make_dir(data_path)
	elif OS.get_name() != "OSX":
#	else:
		# Fix window size
		OS.window_size = OS.window_size / 2
		OS.window_position += OS.window_size / 2
	
	read_game_info()
	
	# Custom background
	load_background_texture()
	
func load_background_texture():
	var d = Directory.new()
	d.change_dir(OS.get_data_dir())
	for ext in ["png", "jpg"]:
		var path = "%s/background.%s" % [CardInfo.data_path, ext]
		if d.file_exists(path):
			var i = Image.new()
			i.load(path)
			background_texture = ImageTexture.new()
			background_texture.create_from_image(i)

func from_game_info_json(content_as_object):
	all_data = content_as_object
	
	all_sigils = all_data["sigils"]
	all_cards = all_data["cards"]
	working_sigils = all_data["working_sigils"]
	
	side_decks = all_data["side_decks"]
	
	if "ruleset" in all_data:
		ruleset = all_data.ruleset
		deck_backup_path = OS.get_user_data_dir() + "/decks/" + ruleset + "/"

func read_game_info():
	
	# Does a downloaded ruleset exist?
	var dir = Directory.new()
	var file = File.new()
	
	if dir.file_exists(rules_path):
		file.open(rules_path, File.READ)
		print(rules_path)
	else:
		print("Downloaded rules not found! Prompting for download")
#		file.open("res://data/gameInfo.json", File.READ)
		get_tree().change_scene("res://AutoUpdate.tscn")
		return
		
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
