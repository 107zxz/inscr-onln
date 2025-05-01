extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_perished" and params[0] == card:
		
		print("Bomb Latch triggered!")
		
		var slot = card.slot_idx()
		
		# Store the previous game state
		if fightManager.pre_snipe_state == null:
			fightManager.pre_snipe_state = fightManager.state
		
		# Anyone to snipe?
		if len(slotManager.all_friendly_cards()) + len(slotManager.all_enemy_cards()) == 0 or fightManager.get_node("MoonFight/BothMoons/" + ("EnemyMoon" if is_friendly else "FriendlyMoon")).visible:
			return
		
		if is_friendly:
			# Become intangible too
			card.get_node("AnimationPlayer").stop()
			card.get_node("CardBody/CardBtn").mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.consider_dead = true
			
			# Wait for attacker to possibly die
			if fightManager.pre_snipe_state == fightManager.GameStates.BATTLE:
				yield(slotManager, "complete_combat")
				fightManager.pre_snipe_state = fightManager.GameStates.DRAWPILE
				yield(card.get_tree().create_timer(0.5), "timeout")

			# Repeat check
			if len(slotManager.all_friendly_cards()) + len(slotManager.all_enemy_cards()) == 0:
				card.queue_free()
				return
			
			# FIRST: Wait for sniping to end if it is in progress.
			while fightManager.state == fightManager.GameStates.SNIPE:
				yield(fightManager, "snipe_complete")
			
			fightManager.sniper = card
			fightManager.state = fightManager.GameStates.SNIPE
			fightManager.snipe_is_attack = false

		# Target[0] is the is_friendly flag set in the RPC. This should represent whether the TARGET is friendly to THE LATCHER
		var target = null
		while target == null or target[0] != is_friendly or target[1] != slot:
			target = yield(fightManager, "snipe_complete")
		target = slotManager.get_friendly_card(target[3]) if target[2] else slotManager.get_enemy_card(target[3])
		
		if "sigils" in target.card_data:
			# Deep copy sigil array
			var n_sigils = target.card_data.sigils.duplicate()
			n_sigils.append("Detonator")
			target.card_data.sigils = n_sigils
		else:
			target.card_data.sigils = ["Detonator"]
		
		var old_atk = target.attack
		var old_hp = target.health	
		target.from_data(target.card_data)
		target.attack = old_atk
		target.health = old_hp
		
		if is_friendly:
			card.queue_free()
			fightManager.state = fightManager.pre_snipe_state
