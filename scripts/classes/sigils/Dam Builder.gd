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
				slotManager.summon_card(CardInfo.from_name("Dam"), slot - 1, isFriendly)

			if slot < CardInfo.all_data.n_lanes - 1 and slotManager.is_slot_empty(cardSlots[slot + 1]):
				slotManager.summon_card(CardInfo.from_name("Dam"), slot + 1, isFriendly)
