extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with
# 'event' representing what happened
func handle_event(event: String, params: Array):

	# Did a card with the Acupuncture symbol just get hit?
	if event == "card_hit" and params[0].has_sigil("Acupuncture"):
		# params[0] == card hit
		# params[1] == card that hit it

		# card is this card
		if card.is_alive():
			print("Sympathetic Connection triggered!")
			# Take damage equal to the inbound attack
			card.take_damage(params[0], params[1].attack)
