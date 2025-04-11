extends SigilEffect

# This is called whenever the card with this sigil takes damage, and modifies the damage taken
func modify_damage_taken(dmg_amt: int):
	return max(dmg_amt, 1)
