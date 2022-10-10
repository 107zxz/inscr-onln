extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):
	
	print("Bomb Spewer recieved event: ", event, "and friendly = ", isFriendly)

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_summoned" and params[0] == card:
		for cSlot in range(4):
			if slotManager.is_slot_empty(slotManager.playerSlots[cSlot]):
				slotManager.summon_card(CardInfo.from_name("Explode Bot"), cSlot, true)
				
			if slotManager.is_slot_empty(slotManager.enemySlots[cSlot]):
				slotManager.summon_card(CardInfo.from_name("Explode Bot"), cSlot, false)
