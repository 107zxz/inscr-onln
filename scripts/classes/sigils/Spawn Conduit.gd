extends SigilEffect

#Used for sigils that do something at the end of the turn
func end_of_turn(card_anim):
	var conduit_data = slotManager.friendly_conduit_data if is_friendly else slotManager.enemy_conduit_data
	if(conduit_data[0] == conduit_data[1]):
		return
	var slot_data = slotManager.player_slots if is_friendly else slotManager.enemy_slots
	for sIdx in range(conduit_data[0], conduit_data[1]):
		if slotManager.is_slot_empty(slot_data[sIdx]):
			slotManager.summon_card(CardInfo.from_name("L33pB0t"), sIdx, is_friendly)
