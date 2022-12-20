extends Label

var dialogue: Dictionary = {}

var currentRoom: Dictionary = {}

func _ready():
	load_dialogue()

func load_dialogue():
	
	var dFile = File.new()
	dFile.open("res://ARG/dialogue.json", File.READ)
	
	print(dFile.get_as_text())

func load_room(room_name: String):
	pass
