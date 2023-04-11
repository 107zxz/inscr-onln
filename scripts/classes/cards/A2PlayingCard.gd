extends "res://scripts/classes/cards/A2Card.gd"


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_COMMA:
			card_data["blood_cost"] -= 1
			draw_costs(card_data)
		if event.scancode == KEY_PERIOD:
			card_data["blood_cost"] += 1
			draw_costs(card_data)
			
