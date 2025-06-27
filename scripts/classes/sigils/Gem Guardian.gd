extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_summoned" and params[0] == card:
		
		print("Gem Guardian triggered!")
		
		for card2 in slotManager.all_friendly_cards() if is_friendly else slotManager.all_enemy_cards():
			if "Mox" in card2.card_data.name:
				card2.get_node("CardBody/Highlight").visible = true
				if "sigils" in card2.card_data:
				# Deep copy sigil array
					var n_sigils = card2.card_data.sigils.duplicate()
					n_sigils.append("Armored")
					card2.card_data.sigils = n_sigils
				else:
					card2.card_data.sigils = ["Armored"]
					
				var old_atk = card2.attack
				var old_hp = card2.health
				card2.from_data(card.card_data)
				card2.attack = old_atk
				card2.health = old_hp
