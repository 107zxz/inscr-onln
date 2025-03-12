extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_perished" and params[0] == card:
		if not params[0].has_sigil("Boneless"):
			# Assume 1 bone already added from regular death
			if isFriendly:	
				fightManager.add_bones(3)
			else:
				fightManager.add_opponent_bones(3)
