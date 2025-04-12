extends SigilEffect

#now, instead of a bunch of hardcoded bullshit, we just simulate what would (probably) happen if the burrower moved to the slot, and if it would intercept, it moves.
func pre_enemy_attack(attacker, targeted_index: int, current_targeting):
	if current_targeting == AttackTargeting.SCALE:
		if (isFriendly and slotManager.is_slot_empty(slotManager.playerSlots[targeted_index])) or (isFriendly and slotManager.is_slot_empty(slotManager.enemySlots[targeted_index])):
			var targeting_test = AttackTargeting.CARD
			for sig in attacker.sigils:
				targeting_test = sig.attacker_target_selecting(targeting_test, card)
			for sig in card.sigils:
				targeting_test = sig.defender_target_selecting(targeting_test, attacker)
			if targeting_test != AttackTargeting.SCALE:
				if isFriendly:
					card.move_to_parent(slotManager.playerSlots[targeted_index])
				else:
					card.move_to_parent(slotManager.enemySlots[targeted_index])
