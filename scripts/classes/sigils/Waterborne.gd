extends SigilEffect

#Used for sigils that determine how cards attacking its space will attack
func defender_target_selecting(current_targeting, attacking_card):
	# Aquanaut unfortunately cannot be added normally, so to impliment it, simply add: `and not attacking_card.has_sigil("Aquanaut")`
	if current_targeting == AttackTargeting.CARD and card.get_node("CardBody/DiveOlay").visible:
		return AttackTargeting.SCALE
	return current_targeting

#Used for sigils that do something at the end of the turn
func end_of_turn(card_anim):
	card_anim.play("Dive")
	yield(card_anim, "animation_finished")
	
#Used for sigils that do something at the start of the turn
func start_of_turn(card_anim):
	card_anim.play("UnDive")
