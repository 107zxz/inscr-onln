extends SigilEffect

func defender_target_selecting(current_targeting, attacking_card):
	if current_targeting == AttackTargeting.CARD:
		return AttackTargeting.FAILURE
	return current_targeting

#Priority is negative such that it runs after Mighty Leap
func priority():
	return -1
