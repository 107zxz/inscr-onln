extends SigilEffect


# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_perished" and params[0] == card and isFriendly:
		
		print("Solute triggered!")
		
#		if fightManager.get_node("")
		
		fightManager.draw_card(card.cardData)
