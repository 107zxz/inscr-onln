extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func modify_attack_targeting(index: int, strikes: Array):
	strikes[index] += 1
	return strikes
