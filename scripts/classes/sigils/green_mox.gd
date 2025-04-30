extends SigilEffect

#Used for sigils that passively define the power of the card they're attached to, such as Ant, Spilled Blood, etc...
func define_power():
	var attack = 0
	for mx in slotManager.all_friendly_cards() if isFriendly else slotManager.all_enemy_cards():
		if "sigils" in mx.cardData and "Green Mox" in mx.cardData["sigils"]:
			attack += 1
	return attack

#IMPORTANT: replace this with 'return true' for any sigil that sets the user's Power/Attack. Returns false otherwise, as a card can only have one of these at once. 
func is_power_defining():
	return true
