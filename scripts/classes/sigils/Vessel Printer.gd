extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# Did this card just get hit?
	if event == "card_hit" and params[0] == card and is_friendly:
		
		# params[0] == card hit
		# params[1] == card that hit it

		if fightManager.side_deck.size() == 0:
			return
			
		fightManager.draw_card(fightManager.side_deck.pop_front(), fightManager.get_node("DrawPiles/YourDecks/SideDeck"))

		# Some interaction here if your deck has less than 3 cards. Don't punish I guess?
		if fightManager.side_deck.size() == 0:
			fightManager.get_node("DrawPiles/YourDecks/SideDeck").visible = false

