extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# Did this card just get hit?
	if event == "card_perished" and params[0] == card:

		print("Steel Trap Triggered!")

		var slot_idx = card.slot_idx()

		var target = slotManager.get_enemy_card(slot_idx) if isFriendly else slotManager.get_friendly_card(slot_idx)

		if not target:
			return

		var pelt_name = "Wolf Pelt"

		# Which pelt to give
		if "rare" in target.card_data:
			pelt_name = "Golden Pelt"
		elif target.card_data.attack == 0:
			pelt_name = "Rabbit Pelt"

		# Kill it
		target.get_node("AnimationPlayer").play("Perish")

		if not isFriendly:
			# Draw the rabbit
			fightManager.draw_card(CardInfo.from_name(pelt_name))
