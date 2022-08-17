class_name SigilEffect

# References
var fightManager = null # See FightManager.gd
var slotManager = null # See CardSlots.gd
var isFriendly = null # Whether the card the sigil is attached to is owned by the local player
var card = null # The card the sigil is attached to

func handle_event(_event: String, _params: Array):
	pass
