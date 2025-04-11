extends SigilEffect

#Used for sigils that passively define the power of the card they're attached to, such as Ant, Spilled Blood, etc...
func define_power():
	var attack = 4 - card.slot_idx()
	for c in slotManager.all_friendly_cards() if card.friendly else slotManager.all_enemy_cards():
		if abs(c.slot_idx() - card.slot_idx()) == 1 and "Chime" in c.card_data["name"]:
			attack += 1
	return attack

#IMPORTANT: replace this with 'return true' for any sigil that sets the user's Power/Attack. Returns false otherwise, as a card can only have one of these at once. 
func is_power_defining():
	return true
