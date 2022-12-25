extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# Was card summoned opposing this one?
	if not card.in_hand:
		if event in ["card_summoned", "card_moved"] and params[0].get_parent().get_parent() != card.get_parent().get_parent() and params[0].slot_idx() == card.slot_idx():
			params[0].take_damage(card, 1)
	
