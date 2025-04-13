extends SigilEffect

func calc_buffs_effect():
		if isFriendly:
			fightManager.no_energy_deplete = (slotManager.friendly_conduit_data[0] != slotManager.friendly_conduit_data[1]) #values are equal when there are 0-1 conduits in play
		else:
			fightManager.enemy_no_energy_deplete = (slotManager.enemy_conduit_data[0] != slotManager.enemy_conduit_data[1]) #values are equal when there are 0-1 conduits in play

#when it dies, turn off no_energy_deplete
func handle_event(event: String, params: Array):
	if event == "card_perished" and params[0] == card:
		if isFriendly:
			fightManager.no_energy_deplete = false
		else:
			fightManager.enemy_no_energy_deplete = false
