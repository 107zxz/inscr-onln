extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_perished" and params[0] == card:
		
		print("Brittle Latch triggered!")
		
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
			fightManager.snipe_enemies_only = false
			
		var target = yield(fightManager, "snipe_complete")
		
		if "sigils" in target.card_data:
			target.card_data.sigils.append("Brittle")
		else:
			target.card_data.sigils = ["Brittle"]
			
		target.from_data(target.card_data)
		
		target.get_node("CardBody/Highlight").visible = true
		
		if isFriendly:
			card.queue_free()
			fightManager.state = prevState
