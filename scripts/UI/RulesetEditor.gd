extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var tree = get_node("%RulesetTree")

# Called when the node enters the scene tree for the first time.
func _ready():
	var root = tree.create_item()
	
	root.set_text(0, "Ruleset")
	
	var cardRoot = tree.create_item(root)
	var sigilRoot = tree.create_item(root)
	cardRoot.set_text(0, "Cards")
	sigilRoot.set_text(0, "Sigils")
	
	tree.create_item(cardRoot).set_text(0, "Amogus")
	
