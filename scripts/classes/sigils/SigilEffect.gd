class_name SigilEffect

const UNDEFINED_DAMAGE_VAL = -1;
const FULLY_NEGATED_DAMAGE_VAL = -2;

enum AttackTargeting {FAILURE, CARD, SCALE}

#KEEP THIS UPDATED
enum SigilTriggers {
	MODIFY_ATTACK_TARGETING,
	MODIFY_DAMAGE_TAKEN,
	ON_DAMAGE_CARD,
	ON_DAMAGE_SCALE,
	START_OF_TURN,
	END_OF_TURN,
	ATTACKER_TARGET_SELECTING,
	DEFENDER_TARGET_SELECTING,
	PRE_ENEMY_ATTACK,
	STAT_MODIFYING_AURA,
	CALC_BUFFS_EFFECT,
	}

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



#Used for sigils that passively define the power of the card they're attached to, such as Ant, Spilled Blood, etc...
#IMPORTANT! Sigils with this effect do not go with normal sigils, they must be put in the 'atkspecial' arguement.
#Note that sigils in 'atkspecial' will be excluded from the normal sigil list(s), meaning none of their other functions will trigger.
func define_power():
	return -1


# YES, ALL OF THESE ARE COMMENTED OUT FOR A REASON. THEY'LL STILL WORK, BECAUSE IF I CAN'T HAVE INTERFACES... I'M GONNA F*CKING FAKE IT!

#Used for sigils that modify how many times the card attacks and in what lanes.
#ex: Bifurcated Strike, Trifrucated Strike, Double strike, Omni strike
#Sniper is unfortunately hardcoded for now.
#func modify_attack_targeting(index: int, strikes: Array):
#	return strikes

#Used for sigils that modify how much damage the attached card is taking.
#ex: Armored, Warded
#func modify_damage_taken(amount: int):
#	return amount

#Used for sigils that do something when damaging another card, although this can still be done with 'handle_event'
#ex: Touch of Death
#func on_damage_card(card_hit, damage: int):
#	pass

#Used for sigils that do something when damaging the scales, although this can still be done with 'handle_event'
#ex: Looter, Side Hustle
#func on_damage_scales(card_hit, damage: int):
#	pass

#Used for sigils that do something at the start of the turn
#ex: Waterborne (cosmetic), Fledgling
#func start_of_turn(cardAnim):
#	pass

#Used for sigils that do something at the end of the turn
#ex: Waterborne (cosmetic), Bone Digger
#func end_of_turn(cardAnim):
#	pass


#ATTACKING AND BLOCKING FUNCTIONS:

#Used for sigils that determine how a card will attack
#ex: Airborne
#func attacker_target_selecting(current_targeting, defending_card):
#	return current_targeting

#Used for sigils that determine how cards attacking its space will attack
#ex: Waterborne, Mighty Leap, Repulsive
#func defender_target_selecting(current_targeting, attacking_card):
#	return current_targeting
	
#Used for sigils that do something when an enemy attempts to attack, but before it's fully determined if that attack will hit
#ex: Burrower
#func pre_enemy_attack(attacker, targeted_index: int, current_targeting):
#	pass



#Used for sigils that passively modify the stats of *other* cards.
#ex: Stinky, Annoying, Leader
#func stat_modifying_aura(card_being_updated, friendly_to_sigilholder: bool):
#	pass

#Used for sigils that need to do something when buffs are calculated
#ex: Energy Conduit
#func calc_buffs_effect():
#	pass

