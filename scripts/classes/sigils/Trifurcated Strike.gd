extends SigilEffect

#Used for sigils that modify how many times the card attacks and in what lanes.
func modify_attack_targeting(index: int, strikes: Array):
	strikes[index+1] += 1
	strikes[index-1] += 1
	return strikes
