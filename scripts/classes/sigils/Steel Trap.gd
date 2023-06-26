extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# Did this card just get hit?
	if event == "card_hit" and params[0] == card:
		
		if params[0].health <= 0 and params[1].is_alive() and not params[1].has_sigil("Made of Stone"):
			print("Steel Trap triggered!")
			params[1].get_node("AnimationPlayer").play("Perish")
