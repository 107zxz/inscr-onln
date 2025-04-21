extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_summoned" and params[0] == card:
		if not "DoublePerish" in card.get_node("AnimationPlayer").current_animation:
		
			print("Dam builder triggered!")
		
			var cardSlots = slotManager.playerSlots if isFriendly else slotManager.enemySlots
			var slot = card.slot_idx()
		
			if slot > 0 and slotManager.is_slot_empty(cardSlots[slot - 1]):
				slotManager.summon_card(CardInfo.from_name("Chime"), slot - 1, isFriendly)

			if slot < 3 and slotManager.is_slot_empty(cardSlots[slot + 1]):
				slotManager.summon_card(CardInfo.from_name("Chime"), slot + 1, isFriendly)
	
	if event == "card_hit" and params[0].card_data.name == "Chime" and params[0].get_parent().get_parent() == card.get_parent().get_parent() \
	or event == "card_hit" and "atkspecial" in params[0].card_data and params[0].card_data.atkspecial == "Bell" and params[0].get_parent().get_parent() == card.get_parent().get_parent():
		
		#if not params[1].has_sigil("Repulsive"):
		if slotManager.get_attack_targeting(isFriendly, card, params[1]) != SigilEffect.AttackTargeting.FAILURE: #Updated to include potential future sigils that would prevent the daus from attacking
			# Don't Strike dying cards
			if params[1].get_node("AnimationPlayer").current_animation != "DoublePerish" and params[1].get_node("AnimationPlayer").current_animation != "Perish":
			
				print("DDDAAAAAAUUUUUSS")

				# Trigger an attack with the appropriate strike offset
		
				# Lower slot to right for attack anim (JANK AF)
				if card.slot_idx() < 3:
					card.get_parent().get_parent().get_child(card.slot_idx() + 1).show_behind_parent = true
		
				card.strike_offset = params[1].slot_idx() - card.slot_idx()
		
				card.rect_position.x = card.strike_offset * 50
		
				card.get_node("AnimationPlayer").play("Attack")
		
				yield(card.get_node("AnimationPlayer"), "animation_finished")
		
				card.strike_offset = 0
				card.rect_position.x = card.strike_offset * 50
		
				if card.slot_idx() < 3:
					card.get_parent().get_parent().get_child(card.slot_idx() + 1).show_behind_parent = false
		
				if card.health <= 0:
					card.get_node("AnimationPlayer").play("Perish")
			
