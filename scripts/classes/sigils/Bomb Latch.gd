extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_perished" and params[0] == card:
		
		print("Bomb Latch triggered!")
		
		var prevState = fightManager.state
		
		# Anyone to snipe?
		if len(slotManager.all_friendly_cards()) + len(slotManager.all_enemy_cards()) == 0:
			return
		
		if isFriendly:
			card.get_node("AnimationPlayer").stop()
			
			# Wait for attacker to possibly die
			if prevState == fightManager.GameStates.BATTLE:
				yield(slotManager, "complete_combat")
			
			# Repeat check
			if len(slotManager.all_friendly_cards()) + len(slotManager.all_enemy_cards()) == 0:
				card.queue_free()
				return
			
			fightManager.sniper = card
			fightManager.state = fightManager.GameStates.SNIPE
			fightManager.snipe_is_attack = false
			
		var target = yield(fightManager, "snipe_complete")
		target = slotManager.get_friendly_card(target[1]) if not target[0] else slotManager.get_enemy_card(target[1])
		
		if "sigils" in target.card_data:
			var n_sigils = target.card_data.sigils
			n_sigils.append("Detonator")
			target.card_data.sigils = n_sigils
		else:
			target.card_data.sigils = ["Detonator"]
			
		target.from_data(target.card_data)
		
		if isFriendly:
			card.queue_free()
			fightManager.state = prevState
