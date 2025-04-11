extends SigilEffect

func defender_target_selecting(current_targeting, attacking_card):
	if current_targeting == AttackTargeting.CARD:
		return AttackTargeting.FAILURE
	return current_targeting
