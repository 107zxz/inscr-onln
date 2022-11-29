extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_summoned" and params[0] == card:
		
		var dam_data = CardInfo.from_name("Dam")

		for sid in [card.slot_idx() - 1, card.slot_idx() + 1]:
			if sid < 0 or sid > 3:
				continue

			if slotManager.is_slot_empty(sid):
				slotManager.summon_card(dam_data, sid, isFriendly) 
