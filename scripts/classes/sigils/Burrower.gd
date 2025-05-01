extends SigilEffect

#Used for sigils that do something when an enemy attempts to attack, but before it's fully determined if that attack will hit

func pre_enemy_attack(attacker, targeted_index: int, current_targeting):
	if current_targeting == AttackTargeting.SCALE:
		if (is_friendly and slotManager.is_slot_empty(slotManager.player_slots[targeted_index])) or (not is_friendly and slotManager.is_slot_empty(slotManager.enemy_slots[targeted_index])):
			#now, instead of a bunch of hardcoded bullshit, we just simulate what (probably) would happen if the burrower moved to the slot, and if it would intercept, it moves.
			if slotManager.get_attack_targeting(is_friendly, attacker, card) != AttackTargeting.SCALE:
				if is_friendly:
					card.move_to_parent(slotManager.player_slots[targeted_index])
				else:
					card.move_to_parent(slotManager.enemy_slots[targeted_index])
