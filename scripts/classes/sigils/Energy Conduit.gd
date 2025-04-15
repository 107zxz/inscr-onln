extends SigilEffect

#Used for sigils that need to do something when buffs are calculated
#might be a little hard to read, but it works perfectly ;)
func calc_buffs_effect():
		if isFriendly:
			fightManager.no_energy_deplete = (slotManager.friendly_conduit_data[0] != slotManager.friendly_conduit_data[1]) #values are equal when there are 0-1 conduits in play
		else:
			fightManager.enemy_no_energy_deplete = (slotManager.enemy_conduit_data[0] != slotManager.enemy_conduit_data[1]) #values are equal when there are 0-1 conduits in play

#when it dies, assume there's no other active Energy Conduits. If there is, it'll fix itself automatically as calc_buffs_effect is called on all cards when a card dies.
func handle_event(event: String, params: Array):
	if event == "card_perished" and params[0] == card:
		if isFriendly:
			fightManager.no_energy_deplete = false
		else:
			fightManager.enemy_no_energy_deplete = false
