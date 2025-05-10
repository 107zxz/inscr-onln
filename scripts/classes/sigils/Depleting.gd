extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_summoned" and params[0] == card:
		
		
#		if (fightManager.max_energy if is_friendly else fightManager.opponent_max_energy) < 2:
#			return
		
		if is_friendly:
			fightManager.set_max_energy(max(fightManager.max_energy - 2, 0))
			fightManager.set_energy(min(fightManager.max_energy + fightManager.max_energy_buff, fightManager.energy))
		else:
			fightManager.set_opponent_max_energy(max(fightManager.opponent_max_energy - 2, 0))
			fightManager.set_opponent_energy(min(fightManager.opponent_max_energy + fightManager.opponent_max_energy_buff, fightManager.opponent_energy))
