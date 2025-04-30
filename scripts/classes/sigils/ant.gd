extends SigilEffect

#Used for sigils that passively define the power of the card they're attached to, such as Ant, Spilled Blood, etc...
func define_power():
	var attack = card.cardData.attack
	for ant in slotManager.all_friendly_cards() if isFriendly else slotManager.all_enemy_cards():
		if "Ant" in ant.cardData["name"] and "ant_limit" in CardInfo.all_data and attack < CardInfo.all_data.ant_limit:
			attack += 1
	return attack

