extends SigilEffect

#Used for sigils that modify how much damage the attached card is taking.
func modify_damage_taken(dmg_amt: int):
	return max(dmg_amt, 1)
