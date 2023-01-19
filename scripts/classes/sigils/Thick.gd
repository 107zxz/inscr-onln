extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_summoned" and params[0] == card:
		
		print("Thick triggered!")
		
		var cardSlots = slotManager.playerSlots if isFriendly else slotManager.enemySlots
		var slot = card.slot_idx()
		
		
		if slot < 3 and slotManager.is_slot_empty(cardSlots[slot + 1]):
			slotManager.summon_card(CardInfo.from_name("Droid"), slot + 1, isFriendly)
			card.from_data(CardInfo.from_name("Thick"))

		elif slot > 0 and slotManager.is_slot_empty(cardSlots[slot - 1]):
			slotManager.summon_card(CardInfo.from_name("Thick"), slot - 1, isFriendly)
			card.from_data(CardInfo.from_name("Droid"))
