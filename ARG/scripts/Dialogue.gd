extends Label

var dialogue: Dictionary = {}

var currentRoom: Dictionary = {}

func _ready():
	load_dialogue()

func load_dialogue():
	
	var dialog_file = File.new()
	dialog_file.open("res://ARG/dialogue.json", File.READ)
	
	print(dialog_file.get_as_text())

func load_room(room_name: String):
	pass
