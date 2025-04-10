class_name SigilEffect

const UNDEFINED_DAMAGE_VAL = -1;
const FULLY_NEGATED_DAMAGE_VAL = -2;

# References
var fightManager = null # See FightManager.gd
var slotManager = null # See CardSlots.gd
var isFriendly = null # Whether the card the sigil is attached to is owned by the local player
var card = null # The card the sigil is attached to

func handle_event(_event: String, _params: Array):
	pass

func modify_attack_targeting(index: int, strikes: Array):
	return strikes
	
func modify_damage_taken(amount: int):
	return amount
