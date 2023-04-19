extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_summoned" and params[0] == card:

<<<<<<< HEAD
		card.get_node("CardBody/Highlight").visible = true
=======
		card.get_node("CardBody/HighlightHolder").visible = true
>>>>>>> c662b41e61700bd6a71b4ede78f54e77d08bb8fa
