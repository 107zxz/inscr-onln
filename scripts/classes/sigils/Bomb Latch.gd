extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_perished" and params[0] == card:
		
		print("Bomb Latch triggered!")
		
		var prevState = fightManager.state
		
		# Anyone to snipe?
		if len(slotManager.all_friendly_cards()) + len(slotManager.all_enemy_cards()) == 0 or fightManager.get_node("MoonFight/BothMoons/" + ("EnemyMoon" if isFriendly else "FriendlyMoon")).visible:
			return
		
		if isFriendly:
			# Become intangible too
			card.get_node("AnimationPlayer").stop()
			card.get_node("CardBody/CardBtn").mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.consider_dead = true
			
			# Wait for attacker to possibly die
			if prevState == fightManager.GameStates.BATTLE:
				yield(slotManager, "complete_combat")
				prevState = fightManager.GameStates.DRAWPILE
				yield(card.get_tree().create_timer(0.5), "timeout")

			# Repeat check
			if len(slotManager.all_friendly_cards()) + len(slotManager.all_enemy_cards()) == 0:
				card.queue_free()
				return
			
			fightManager.sniper = card
			fightManager.state = fightManager.GameStates.SNIPE
			fightManager.snipe_is_attack = false

		# Target[0] is the is_friendly flag set in the RPC. This should represent whether the TARGET is friendly to THE LATCHER
		var target = yield(fightManager, "snipe_complete")
		target = slotManager.get_friendly_card(target[1]) if target[0] == isFriendly else slotManager.get_enemy_card(target[1])
		
		if "sigils" in target.card_data:
			# Deep copy sigil array
			var n_sigils = target.card_data.sigils.duplicate()
			n_sigils.append("Detonator")
			target.card_data.sigils = n_sigils
		else:
			target.card_data.sigils = ["Detonator"]
			
		target.from_data(target.card_data)
		
		if isFriendly:
			card.queue_free()
			fightManager.state = prevState
