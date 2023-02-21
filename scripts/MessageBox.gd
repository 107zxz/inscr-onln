class_name MessageBox
extends Control

class DialogueEvent:
	export var dialogue:String = ""
	export var speed:float = 10.0
	export var expression:Texture
	export var auto_continue:bool
	
	func _init(vals:Dictionary):
		for key in vals:
			# I am lazy
			set(key, vals[key])
		pass

func do_dialogue(events:Array): # events must mbe an array of DialogueEvents.
	get_tree().paused = true
	visible = true
	
	var advance :Button = $Advance
	var emotion :TextureRect = $Emotion
	var display :Label = $DialogueDisplay
	var tween :SceneTreeTween = create_tween()
	
	for event in events:
		if tween != null and tween.is_valid():
			tween.stop()
		display.text = ""
		tween.tween_property(display, "text", event.dialogue, len(event.dialogue) / event.speed)
		tween.play()
		yield(advance, "pressed")
	
	get_tree().paused = false
	visible = false
