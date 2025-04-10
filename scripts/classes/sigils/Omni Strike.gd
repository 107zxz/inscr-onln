extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):
	pass
	
func modify_attack_targeting(index: int, strikes: Array):
	strikes[index] += 1
	for eCard in card.all_enemy_cards():
		strikes[eCard.slot_idx()] = 1
	if not 1 in strikes:
		strikes[index] = 1
	return strikes
