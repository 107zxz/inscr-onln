extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_perished" and params[0] == card and isFriendly:
		
		print("Unkillable triggered!")
		
		var old_data = card.card_data.duplicate()
		old_data.sigils = old_data.sigils.duplicate()

		old_data.sigils.erase("Unkillable (Eternal)")

		# Draw the modified card copy
		fightManager.draw_card(old_data)
