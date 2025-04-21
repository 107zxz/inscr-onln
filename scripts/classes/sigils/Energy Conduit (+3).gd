extends SigilEffect

#Used for sigils that need to do something when buffs are calculated
func calc_buffs_effect():
		if isFriendly:
			if slotManager.friendly_conduit_data[0] != slotManager.friendly_conduit_data[1]: #values are equal when there are 0-1 conduits in play
				if fightManager.max_energy_buff == 0:
					fightManager.max_energy_buff = 3
					fightManager.set_max_energy(fightManager.max_energy)
					fightManager.set_energy(fightManager.energy + fightManager.max_energy_buff)
			else:
				if fightManager.max_energy_buff != 0:
					fightManager.max_energy_buff = 0
					fightManager.set_max_energy(fightManager.max_energy)
					fightManager.set_energy(min(fightManager.energy, fightManager.max_energy))
		else:
			if slotManager.enemy_conduit_data[0] != slotManager.enemy_conduit_data[1]: #values are equal when there are 0-1 conduits in play
				if fightManager.opponent_max_energy_buff == 0:
					fightManager.opponent_max_energy_buff = 3
					fightManager.set_opponent_max_energy(fightManager.max_energy)
					fightManager.set_opponent_energy(fightManager.energy + fightManager.max_energy_buff)
			else:
				if fightManager.opponent_max_energy_buff != 0:
					fightManager.opponent_max_energy_buff = 0
					fightManager.set_opponent_max_energy(fightManager.opponent_max_energy)
					fightManager.set_opponent_energy(min(fightManager.opponent_energy, fightManager.opponent_max_energy))

#when it dies, assume there's no other active Energy Conduit (+3). If there is, it'll fix itself automatically as calc_buffs_effect is called on all cards when a card dies.
func handle_event(event: String, params: Array):
	if event == "card_perished" and params[0] == card:
		if isFriendly:
			if fightManager.max_energy_buff != 0:
				fightManager.max_energy_buff = 0
				fightManager.set_max_energy(fightManager.max_energy)
				fightManager.set_energy(min(fightManager.energy, fightManager.max_energy))
		else:
			if fightManager.opponent_max_energy_buff != 0:
				fightManager.opponent_max_energy_buff = 0
				fightManager.set_opponent_max_energy(fightManager.opponent_max_energy)
				fightManager.set_opponent_energy(min(fightManager.opponent_energy, fightManager.opponent_max_energy))
