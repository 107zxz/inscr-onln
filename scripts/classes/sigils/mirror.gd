extends SigilEffect

#Used for sigils that passively define the power of the card they're attached to, such as Ant, Spilled Blood, etc...
func define_power():
	var sIdx = card.slot_idx()
	if is_friendly:
		if slotManager.get_enemy_card(sIdx):
			return slotManager.get_enemy_card(sIdx).attack
	else:
		if slotManager.get_friendly_card(sIdx):
			return slotManager.get_friendly_card(sIdx).attack

#IMPORTANT: replace this with 'return true' for any sigil that sets the user's Power/Attack. Returns false otherwise, as a card can only have one of these at once. 
func is_power_defining():
	return true
