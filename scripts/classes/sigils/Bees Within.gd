extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# Did this card just get hit?
	if event == "card_hit" and params[0] == card and is_friendly:
		
		# params[0] == card hit
		# params[1] == card that hit it
		
		fightManager.draw_card(CardInfo.from_name("Bee"))
