extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_summoned" and params[0] == card and isFriendly:

		fightManager.set_max_energy(min(fightManager.max_energy + 1, 6))
		
		# Energy conduit stuff
		fightManager.set_energy(min(fightManager.max_energy + fightManager.max_energy_buff, fightManager.energy + 1))
