extends SigilEffect

func defender_target_selecting(current_targeting, attacking_card):
	# Aquanaut unfortunately cannot be added normally, so to impliment it, simply add: `and not attacking_card.has_sigil("Aquanaut")`
	if current_targeting == AttackTargeting.CARD and card.get_node("CardBody/DiveOlay").visible:
		return AttackTargeting.SCALE
	return current_targeting

#Used for sigils that do something at the end of the turn
#ex: Waterborne (cosmetic), Bone Digger
func end_of_turn(cardAnim):
	cardAnim.play("Dive")
	yield(cardAnim, "animation_finished")
	
func start_of_turn(cardAnim):
	cardAnim.play("UnDive")
