extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# Did this card just get hit?
	if event == "card_hit" and params[1] == card and params[0].get_node("AnimationPlayer").current_animation == "Perish":
		if params[1].get_node("AnimationPlayer").current_animation == "Attack":
			card.cardData.attack += 1
			card.draw_stats()
