extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):
	
	if event == "card_perished" and params[0] == card:
		
		var sIdx = card.slot_idx()
		
		var slot = slotManager.playerSlots[sIdx] if isFriendly else slotManager.enemySlots[sIdx]
		
		if slotManager.is_slot_empty(slot):
			if "evolution" in card.card_data:
				slotManager.summon_card(CardInfo.from_name(card.card_data["evolution"]), card.slot_idx(), isFriendly)
			else:
				if "frozen_card" in CardInfo.all_data:
					slotManager.summon_card((CardInfo.from_name(CardInfo.all_data.frozen_card)), card.slot_idx(), isFriendly)
				else:
					slotManager.summon_card(CardInfo.from_name("Opossum"), card.slot_idx(), isFriendly)
