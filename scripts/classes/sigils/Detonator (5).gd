extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):
	
	# Rewrite this
	
	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_perished" and params[0] == card:

		var slotIdx = card.slot_idx()
		
		print(("friendly" if isFriendly else "enemy"), " boombot perished in slot ", slotIdx)
		
		if isFriendly:
			# Attack the moon
			if fightManager.get_node("MoonFight/BothMoons/EnemyMoon").visible:
				fightManager.get_node("MoonFight/BothMoons/EnemyMoon").take_damage(5)

			elif not slotManager.is_slot_empty(slotManager.enemySlots[slotIdx]):
				var eCard = slotManager.get_enemy_card(slotIdx)

				if not "Perish" in eCard.get_node("AnimationPlayer").current_animation:
					eCard.take_damage(card, 4)
#				
			# Kill adjacents
			for offset in [-1, 1]:
				
				var eCard = slotManager.get_friendly_card(slotIdx + offset)
				
				if eCard and not "Perish" in eCard.get_node("AnimationPlayer").current_animation:
					eCard.take_damage(card, 5)
		else:
			# Attack the moon
			if fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").visible:

				fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").take_damage(5)
				
			elif not slotManager.is_slot_empty(slotManager.playerSlots[slotIdx]):
				var eCard = slotManager.get_friendly_card(slotIdx)

				if not "Perish" in eCard.get_node("AnimationPlayer").current_animation:
					eCard.take_damage(card, 5)
#				
			# Kill adjacents
			for offset in [-1, 1]:
				
				var eCard = slotManager.get_enemy_card(slotIdx + offset)
				
				if eCard and not "Perish" in eCard.get_node("AnimationPlayer").current_animation:
					eCard.take_damage(card, 5)
