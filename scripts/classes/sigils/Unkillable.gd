extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_perished" and params[0] == card:
		if isFriendly:
			var old_data = card.cardData.duplicate()
			print("Unkillable triggered!")
			if "death_buff" in card.cardData and params[0].cardData.name == card.cardData.name:
				if params[0].get_node("AnimationPlayer").current_animation == "DoublePerish":
					old_data.attack += 2
					old_data.health += 2
				else:
					old_data.attack += 1
					old_data.health += 1
					
			for hCard in fightManager.handManager.get_node("PlayerHand").get_children():
				if "death_buff" in card.cardData and params[0].cardData.name == hCard.cardData.name:
					hCard.attack += 1
					hCard.cardData.attack += 1 
					hCard.health += 1
					hCard.cardData.health += 1
					hCard.draw_stats()
			# Draw the modified card copy
			fightManager.draw_card(old_data)
		
		var friendlies = slotManager.all_friendly_cards() if isFriendly else slotManager.all_enemy_cards()
		for fCard in friendlies:
			if "death_buff" in card.cardData and params[0].cardData.name == fCard.cardData.name:
				fCard.cardData.attack += 1
				fCard.cardData.health += 1
				fCard.health += 1
