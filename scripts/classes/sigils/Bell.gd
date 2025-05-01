extends SigilEffect

#Used for sigils that passively define the power of the card they're attached to, such as Ant, Spilled Blood, etc...
func define_power():
	var attack = 4 - card.slot_idx()
	for c in slotManager.all_friendly_cards() if is_friendly else slotManager.all_enemy_cards():
		if abs(c.slot_idx() - card.slot_idx()) == 1 and "Chime" in c.card_data["name"]:
			attack += 1
	return attack
