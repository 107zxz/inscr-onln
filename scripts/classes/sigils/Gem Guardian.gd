extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_summoned" and params[0] == card:
		
		print("Gem Guardian triggered!")
		
		for card in slotManager.all_friendly_cards() if isFriendly else slotManager.all_enemy_cards():
			if "Mox" in card.card_data.name:
				card.get_node("CardBody/Highlight").visible = true
