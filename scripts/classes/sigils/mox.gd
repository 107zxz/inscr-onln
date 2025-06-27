extends SigilEffect

#Used for sigils that passively define the power of the card they're attached to, such as Ant, Spilled Blood, etc...
#IMPORTANT! Sigils with this effect do not go with normal sigils, they must be put in the 'atkspecial' arguement.
#Note that sigils in 'atkspecial' will be excluded from the normal sigil list(s), meaning none of their other functions will trigger.
func define_power():
	var attack = 0
	for mx in slotManager.all_friendly_cards() if is_friendly else slotManager.all_enemy_cards():
		if "mox" in mx.card_data["name"].to_lower():
			attack += 1
	return attack
