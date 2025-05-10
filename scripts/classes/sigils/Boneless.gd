extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_perished" and params[0] == card:

		# Assume 1 bone already added from regular death
		if is_friendly:	
			fightManager.add_bones(-1)
		else:
			fightManager.add_opponent_bones(-1)
