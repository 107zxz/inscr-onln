extends SigilEffect

#Used for sigils that do something when damaging the scales, although this can still be done with 'handle_event'
func on_damage_scale(damage: int):
	for _i in range(damage):
		if fightManager.side_deck.size() == 0:
			break

		fightManager.draw_card(fightManager.side_deck.pop_front(), fightManager.get_node("DrawPiles/YourDecks/SideDeck"))

		# Some interaction here if your deck has less than 3 cards. Don't punish I guess?
		if fightManager.side_deck.size() == 0:
			slotManager.get_node("../DrawPiles/YourDecks/SideDeck").visible = false
			break
