extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_perished" and params[0] == card and isFriendly:
		
		print("Reconstitute triggered!")
		
		var old_data = card.card_data.duplicate()

		if card.card_data.name == "Ouroboros":
			old_data.attack += 1
			old_data.health += 1

		fightManager.gold_sarcophagus.append(
			{
				"card": old_data,
				"turnsleft": 1
			}
		)
