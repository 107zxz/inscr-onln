extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_perished" and params[0] == card:
		if isFriendly:
			var old_data = card.card_data.duplicate()
			print("Unkillable triggered!")
			if card.card_data.name == "Ouroboros" and params[0].card_data.name != "Ourobot" or card.card_data.name == "Ourobot" and params[0].card_data.name != "Ouroboros":
				if params[0].get_node("AnimationPlayer").current_animation == "DoublePerish":
					old_data.attack += 2
					old_data.health += 2
				else:
					old_data.attack += 1
					old_data.health += 1
					
			for hCard in fightManager.handManager.get_node("PlayerHand").get_children():
				if hCard.card_data.name == "Ouroboros" and params[0].card_data.name != "Ourobot" or hCard.card_data.name == "Ourobot" and params[0].card_data.name != "Ouroboros":
					hCard.attack += 1
					hCard.card_data.attack += 1
					hCard.health += 1
					hCard.card_data.health += 1
					hCard.draw_stats()
			# Draw the modified card copy
			fightManager.draw_card(old_data)
		
		var friendlies = slotManager.all_friendly_cards() if isFriendly else slotManager.all_enemy_cards()
		for fCard in friendlies:
			if fCard.card_data.name == "Ouroboros" and params[0].card_data.name != "Ourobot" or fCard.card_data.name == "Ourobot" and params[0].card_data.name != "Ouroboros":
				fCard.card_data.attack += 1
				fCard.card_data.health += 1
				fCard.health += 1
