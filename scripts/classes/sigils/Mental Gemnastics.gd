extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_summoned" and params[0] == card and isFriendly:
		
		for fCard in slotManager.all_friendly_cards():
			if "Mox" in fCard.card_data["name"]:
				if fightManager.deck.size() == 0:
					break
				fightManager.draw_card(fightManager.deck.pop_front())
					
				# Some interaction here if your deck has less than 3 cards. Don't punish I guess?
				if fightManager.deck.size() == 0:
					fightManager.get_node("DrawPiles/YourDecks/Deck").visible = false
					break
