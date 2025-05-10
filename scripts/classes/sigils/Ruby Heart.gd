extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):
	
	if event == "card_perished" and params[0] == card:
		slotManager.summon_card(CardInfo.from_name("Ruby Mox"), card.slot_idx(), is_friendly)
