extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_perished" and isFriendly and params[0].get_parent().get_parent().name == "PlayerSlots" and card.get_parent().name == "PlayerHand" and fightManager.state == fightManager.GameStates.BATTLE:
		
		print("Corpse Eater triggered!")
		
		var slot = params[0].get_parent()
		
		yield(card.get_tree().create_timer(0.1), "timeout")
		
		if not slotManager.is_slot_empty(slot):
			return
		
		fightManager.send_move({
				"type": "raise_card",
				"index": card.get_position_in_parent()
			})
			
		card.move_to_parent(slot)
		
		fightManager.send_move({
				"type": "play_card",
				"card": card.cardData,
				"slot": slot.get_position_in_parent(),
				"ignore_cost": true
			})
		
		
		
