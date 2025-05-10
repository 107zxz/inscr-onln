extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):
	
	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_summoned" and params[0] == card:
		if not "DoublePerish" in card.get_node("AnimationPlayer").current_animation:
			for cSlot in range(CardInfo.all_data.lanes):
				if slotManager.is_slot_empty(slotManager.player_slots[cSlot]):
					slotManager.summon_card(CardInfo.from_name("Explode Bot"), cSlot, true)
					print("Summoning boombot into friendly slot ", cSlot)
				
				if slotManager.is_slot_empty(slotManager.enemy_slots[cSlot]):
					slotManager.summon_card(CardInfo.from_name("Explode Bot"), cSlot, false)
					print("Summoning boombot into enemy slot ", cSlot)
