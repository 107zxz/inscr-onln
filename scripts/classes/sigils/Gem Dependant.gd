extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# Don't die in hand
	if card.get_parent().name == "PlayerHand":
		return

	# attached_card_summoned represents the card bearing the sigil being summoned
	if (event == "card_summoned" and params[0] == card) or (event == "card_perished" and params[0] != card):

		# Die if no gems
		if not "Perish" in card.get_node("AnimationPlayer").current_animation:

			
			for card in slotManager.all_friendly_cards():
				if card.has_tribe("Mox"):
					return
			card.get_node("AnimationPlayer").play("Perish")
		
