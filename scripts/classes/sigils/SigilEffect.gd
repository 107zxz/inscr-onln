class_name SigilEffect

const UNDEFINED_DAMAGE_VAL = -1;
const FULLY_NEGATED_DAMAGE_VAL = -2;

# References
var fightManager = null # See FightManager.gd
var slotManager = null # See CardSlots.gd
var isFriendly = null # Whether the card the sigil is attached to is owned by the local player
var card = null # The card the sigil is attached to

#Handles signal events, good generic method to use
#ex: Most of them, honestly
#I, WhiteRobot10, am personally not a fan, but it's neccessary (for the time being, at least.)
func handle_event(_event: String, _params: Array):
	pass

#Used for sigils that modify how many times the card attacks and in what lanes.
#ex: Bifurcated Strike, Trifrucated Strike, Double strike, Omni strike
#Sniper is unfortunately hardcoded for now.
func modify_attack_targeting(index: int, strikes: Array):
	return strikes

#Used for sigils that modify how much damage the attached card is taking.
#ex: Armored, Warded
func modify_damage_taken(amount: int):
	return amount

#Used for sigils that do something on dealing damage, although this can still be done with 'handle_event'
#ex: Touch of Death
#Could probably be used for Sharp Quills, but I'll only do that if asked
func on_deal_damage(card_hit, damage: int):
	pass



#Used for sigils that passively modify the stats of *other* cards.
#ex: Stinky, Annoying, Leader
#this theoretically could cause performance issues as it does require looping through EVERY SIGIL ON THE FIELD whenever a card updates, but I know a way to fix this if it's neccessary.
func stat_modifying_aura(card_being_updated, friendly_to_sigilholder: bool):
	pass

#IMPORTANT: replace this with something that returns true for any sigil that uses the stat_modifying_aura function, otherwise it won't work. Returns false otherwise for performance, just in case it matters.
func is_aura():
	return false
