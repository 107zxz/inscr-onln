extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_summoned" and params[0] == card:

		if isFriendly:
			fightManager.set_max_energy(min(fightManager.max_energy + 1, 6))
			fightManager.set_energy(min(fightManager.max_energy + fightManager.max_energy_buff, fightManager.energy + 1))
		else:
			fightManager.set_opponent_max_energy(min(fightManager.opponent_max_energy + 1, 6))
			fightManager.set_opponent_energy(min(fightManager.opponent_max_energy + fightManager.opponent_max_energy_buff, fightManager.opponent_energy + 1))
