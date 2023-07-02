extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_summoned" and params[0] == card:
		
		var atk_acc = 0
		var hp_acc = 0
		var n_sigils = []
		
		var friendlies = slotManager.all_friendly_cards() if isFriendly else slotManager.all_enemy_cards()
		
		for fCard in friendlies:
			if fCard == card:
				continue
			
			atk_acc += fCard.attack
			hp_acc += fCard.health
			
			if "sigils" in fCard.card_data:
				for f_sigil in fCard.card_data.sigils:
					if len(n_sigils) < 3 and not f_sigil in n_sigils:
						n_sigils.append(f_sigil)
			
			fCard.get_node("AnimationPlayer").play("Perish")
		
		var new_data = card.card_data
		
		new_data.attack = atk_acc
		new_data.health = hp_acc
		new_data.sigils = n_sigils
		
		card.from_data(card.card_data)
