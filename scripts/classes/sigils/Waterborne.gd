extends SigilEffect

func defender_target_selecting(current_targeting, attacking_card):
	# Aquanaut unfortunately cannot be added normally, so to impliment it, simply add: `and not attacking_card.has_sigil("Aquanaut")`
	if current_targeting == AttackTargeting.CARD:
		return AttackTargeting.SCALE
	return current_targeting
