extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_summoned" and params[0] == card:
		
		print("Dam builder triggered!")
		
		var cardSlots = slotManager.playerSlots if isFriendly else slotManager.enemySlots
		var slot = card.slot_idx()
		
		if slot > 0 and slotManager.is_slot_empty(cardSlots[slot - 1]):
			slotManager.summon_card(CardInfo.from_name("Chime"), slot - 1, isFriendly)

		if slot < 3 and slotManager.is_slot_empty(cardSlots[slot + 1]):
			slotManager.summon_card(CardInfo.from_name("Chime"), slot + 1, isFriendly)
	
	
	if event == "card_hit" and params[0].card_data.name == "Chime" and params[0].get_parent().get_parent() == card.get_parent().get_parent():
		print("DDDAAAAAAUUUUUSS")
#		params[1].take_damage(card, 1)

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
		
