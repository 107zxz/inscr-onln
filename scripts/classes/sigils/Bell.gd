extends SigilEffect

#Used for sigils that passively define the power of the card they're attached to, such as Ant, Spilled Blood, etc...
func define_power():
	var attack = CardInfo.all_data.n_lanes - card.slot_idx()
	for c in slotManager.all_friendly_cards() if isFriendly else slotManager.all_enemy_cards():
		if abs(c.slot_idx() - card.slot_idx()) == 1 and "Chime" in c.card_data["name"]:
			attack += 1
	return attack
