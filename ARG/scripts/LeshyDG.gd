extends Node

var dialogue: Array = []
var currentRoom: Dictionary = {}
var awaiting_input: bool = false
var typing: bool = true

var currentSubPassage = 0

var passage_idx = 1

const TEXT_SPEED = 1

func _ready():
	load_dialogue()
	load_passage("entry")

func load_dialogue():
	
	var dFile = File.new()
	dFile.open("res://ARG/dialogue.json", File.READ)
	
	dialogue = parse_json(dFile.get_as_text())

func load_passage(passage_name: String) -> void:
	
	# Update room
#	currentRoom = dialogue[GameOptions.options.misplays][passage_name]
	currentRoom = dialogue[0][passage_name]
	$UI/RoomLabel.text = passage_name
	
	# Dialogue text
	currentSubPassage = 0
	$UI/Dialogue.bbcode_text = "[center]" + currentRoom.text[0] + "[/center]"
	
	$UI/Dialogue.visible = true
	$UI/Arrow.visible = true
	
	

#func display_options():
#
#	# Chat options
#	var opts = currentRoom.opts.keys()
#	$OptionA.hide()
#	$OptionB.hide()
#
#	$DelayTimer.start()
#	yield($DelayTimer, "timeout")
#
#	if len(opts) > 0:
#		$OptionA.text = "1. " + opts[0]
#		$OptionA.show()
#		$OptionA._mouse_exited()
#
#		if len(opts) > 1:
#			$OptionB.text = "2. " + opts[1]
#			$OptionB.show()
#			$OptionB._mouse_exited()


#func display_ibox():
#	$LineInput.show()
#	$LineInput.grab_focus()


#func passage_clicked(passage_name: String):
#	$OptionA.hide()
#	$OptionB.hide()
#
#	$DelayTimer.start()
#	yield($DelayTimer, "timeout")
#	load_passage(currentRoom.opts[passage_name])


#func tick_letter() -> void:
#	if not typing or $Dialogue.visible_characters >= $Dialogue.text.length():
#		return
#
#	$Dialogue.visible_characters += 1
#
#
#	if $Dialogue.visible_characters == $Dialogue.text.length():
#		typing = false
#
#		if currentSubPassage == len(currentRoom.text) - 1 and "opts" in currentRoom:
#
#			if currentRoom.opts.keys()[0] == "[IBOX]":
#				display_ibox()
#			else:
#				display_options()
#
#		else:
#			$UI/Arrow.show()


func _input(event):
	
	if $UI/Arrow.visible:
	
		if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed or (event is InputEventKey and not event.echo) and event.pressed:
			
			if currentSubPassage == len(currentRoom.text) - 1:
				GameOptions.options.misplays = 1
#				GameOptions.mega_misplay = true
				GameOptions.save_options()
				get_tree().change_scene(currentRoom.redir)
				return
			
			# SPECIAL CASE: JIGSAW
			if currentRoom.text[currentSubPassage + 1] == "[jigsaw]":
				$UI/Arrow.visible = false
				$UI/Dialogue.visible = false
				$UI/Puzzle/AnimationPlayer.play("Appear")
				return
			
			if currentRoom.text[currentSubPassage + 1] == "As promised, your [color=#24c8de]boon[/color].":
#				$UI/Arrow.visible = false
#				$UI/Dialogue.visible = false
				$Scene/GSmoke/AnimationPlayer.play("rollin")
				$UI/Puzzle/AnimationPlayer.play("Disappear")
#				return
			
			
			$UI/Dialogue.bbcode_text = "[center]" + currentRoom.text[currentSubPassage + 1] + "[/center]"
#			$UI/Dialogue.visible_characters = 0
			
			$UI/Arrow.visible = false
			$UI/Dialogue.visible = false
#			typing = true
			
			yield(get_tree().create_timer(currentRoom.delays[currentSubPassage]), "timeout")
			
			$UI/Dialogue.visible = true
			$UI/Arrow.visible = true
#			typing = false
			
			currentSubPassage += 1

#	elif false and $OptionB.visible and event is InputEventKey and not event.echo and event.pressed:
#
#		var key = ""
#
#		if event.scancode == KEY_1:
#			key = currentRoom.opts.keys()[0]
#		if event.scancode == KEY_2:
#			key = currentRoom.opts.keys()[1]
#
#		if key != "":
#			passage_clicked(key)

#
#func _on_LineInput_text_entered(_new_text):
#	$LineInput.hide()
#	passage_clicked("[IBOX]")
