extends SigilEffect

func defender_target_selecting(current_targeting, attacking_card):
	if current_targeting == AttackTargeting.SCALE and attacking_card.has_sigil("Airborne"):
		return AttackTargeting.CARD
	return current_targeting
