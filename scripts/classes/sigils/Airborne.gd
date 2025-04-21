extends SigilEffect

#Used for sigils that determine how a card will attack
#we don't put the mightly leap blocking here, that goes in the mighty leap sigil
func attacker_target_selecting(current_targeting, defending_card):
	if current_targeting == AttackTargeting.CARD:
		return AttackTargeting.SCALE
	return current_targeting
