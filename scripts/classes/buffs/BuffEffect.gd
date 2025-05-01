# The idea for this is for each card to have an array of buffs
class_name BuffEffect

# Stacking
const STACK_MAX = 1
var stacks = 1

# References
var fightManager = null
var slotManager = null
var is_friendly = null
var card = null

func handle_event(event: String):
	pass
