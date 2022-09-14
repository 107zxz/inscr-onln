extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):
	
	print("Bomb Spewer recieved event: ", event, "and friendly = ", isFriendly)

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_summoned" and params[0] == card:
		if isFriendly:
			for cSlot in range(4):
				if not slotManager.is_slot_empty(slotManager.playerSlots[cSlot]) or slotManager.playerSlots[cSlot] == card.get_parent():
					continue

				slotManager.summon_card(CardInfo.from_name("Explode Bot"), cSlot)
				slotManager.rpc_id(fightManager.opponent, "remote_card_summon", CardInfo.from_name("Explode Bot"), cSlot)
		else:
			for cSlot in range(4):
				if not slotManager.is_slot_empty(slotManager.playerSlots[cSlot]):
					continue
	
				slotManager.summon_card(CardInfo.from_name("Explode Bot"), cSlot)
				slotManager.rpc_id(fightManager.opponent, "remote_card_summon", CardInfo.from_name("Explode Bot"), cSlot)
	
