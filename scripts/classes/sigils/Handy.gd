extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_summoned" and params[0] == card:
		
		# Discard hand
		for hCard in fightManager.handManager.get_node("PlayerHand" if isFriendly else "EnemyHand").get_children():
			hCard.get_node("AnimationPlayer").play("Discard")

		if isFriendly:
			for _i in range(3):
				if fightManager.deck.size() == 0:
					break
				
				fightManager.draw_card(fightManager.deck.pop_front(), fightManager.get_node("DrawPiles/YourDecks/Deck"))
				
				# Some interaction here if your deck has less than 3 cards. Don't punish I guess?
				if fightManager.deck.size() == 0:
					fightManager.get_node("DrawPiles/YourDecks/Deck").visible = false
					break
				
			fightManager.draw_card(fightManager.side_deck.pop_front(), fightManager.get_node("DrawPiles/YourDecks/SideDeck"))

			if fightManager.side_deck.size() == 0:
				fightManager.get_node("DrawPiles/YourDecks/SideDeck").visible = false
