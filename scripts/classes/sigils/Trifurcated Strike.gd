extends SigilEffect

# This is called whenever the card with this sigil attacks, and modifies which lanes it attacks in
	
func modify_attack_targeting(index: int, strikes: Array):
	strikes[index+1] += 1
	strikes[index-1] += 1
	return strikes
