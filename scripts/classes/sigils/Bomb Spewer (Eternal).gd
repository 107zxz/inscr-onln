extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):
	
#	print("Bomb Spewer recieved event: ", event, "and friendly = ", is_friendly)

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_summoned" and params[0] == card:
		for cSlot in range(4):
			if is_friendly and slotManager.is_slot_empty(slotManager.player_slots[cSlot]) and not slotManager.is_slot_empty(slotManager.enemy_slots[cSlot]):
				slotManager.summon_card(CardInfo.from_name("Explode Bot"), cSlot, true)
				print("Summoning boombot into friendly slot ", cSlot)
			
			if not is_friendly and slotManager.is_slot_empty(slotManager.enemy_slots[cSlot]) and not slotManager.is_slot_empty(slotManager.player_slots[cSlot]):
				slotManager.summon_card(CardInfo.from_name("Explode Bot"), cSlot, false)
				print("Summoning boombot into enemy slot ", cSlot)

