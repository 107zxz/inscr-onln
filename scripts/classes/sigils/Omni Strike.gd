extends SigilEffect

# This is called whenever the card with this sigil attacks, and modifies which lanes it attacks in
func modify_attack_targeting(index: int, strikes: Array):
	strikes[index] -= 1
	for eCard in card.all_enemy_cards():
		strikes[eCard.slot_idx()] = 1
	if not 1 in strikes:
		strikes[index] = 1
	return strikes
