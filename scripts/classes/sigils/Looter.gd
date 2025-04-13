extends SigilEffect

#Used for sigils that do something when damaging the scales, although this can still be done with 'handle_event'
func on_damage_scale(damage: int):
	for _i in range(damage):
		if fightManager.deck.size() == 0:
			break

		fightManager.draw_card(fightManager.deck.pop_front())

		# Some interaction here if your deck has less than 3 cards. Don't punish I guess?
		if fightManager.deck.size() == 0:
			slotManager.get_node("../DrawPiles/YourDecks/Deck").visible = false
			break
