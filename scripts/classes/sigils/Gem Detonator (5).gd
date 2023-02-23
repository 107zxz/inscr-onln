extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	if event != "card_perished":
		return

	if card.get_parent().get_parent() != params[0].get_parent().get_parent():
		return
		
	if params[0] == card:
		return
	
	if not params[0].has_tribe("Mox"):
		return
		
	var slotIdx = params[0].slot_idx()
		
	print(("friendly" if isFriendly else "enemy"), " boomgem perished in slot ", slotIdx)
	
	if isFriendly:
		# Attack the moon
		if fightManager.get_node("MoonFight/BothMoons/EnemyMoon").visible:
			fightManager.get_node("MoonFight/BothMoons/EnemyMoon").take_damage(5)

		elif not slotManager.is_slot_empty(slotManager.enemySlots[slotIdx]):
			var eCard = slotManager.get_enemy_card(slotIdx)

			if not "Perish" in eCard.get_node("AnimationPlayer").current_animation:
				eCard.take_damage(params[0], 5)
#				
		# Kill adjacents
		for offset in [-1, 1]:
			
			var eCard = slotManager.get_friendly_card(slotIdx + offset)
			
			if eCard and not "Perish" in eCard.get_node("AnimationPlayer").current_animation:
				eCard.take_damage(params[0], 5)
	else:
		# Attack the moon
		if fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").visible:

			fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").take_damage(5)
			
		elif not slotManager.is_slot_empty(slotManager.playerSlots[slotIdx]):
			var eCard = slotManager.get_friendly_card(slotIdx)

			if not "Perish" in eCard.get_node("AnimationPlayer").current_animation:
				eCard.take_damage(params[0], 5)
#				
		# Kill adjacents
		for offset in [-1, 1]:
			
			var eCard = slotManager.get_enemy_card(slotIdx + offset)
			
			if eCard and not "Perish" in eCard.get_node("AnimationPlayer").current_animation:
				eCard.take_damage(params[0], 5)

