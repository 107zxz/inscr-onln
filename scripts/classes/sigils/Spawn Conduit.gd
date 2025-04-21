extends SigilEffect

#Used for sigils that do something at the end of the turn
func end_of_turn(cardAnim):
	var conduit_data = slotManager.friendly_conduit_data if isFriendly else slotManager.enemy_conduit_data
	if(conduit_data[0] == conduit_data[1]):
		return
	var slot_data = slotManager.playerSlots if isFriendly else slotManager.enemySlots
	for sIdx in range(conduit_data[0], conduit_data[1]):
		if slotManager.is_slot_empty(slot_data[sIdx]):
			slotManager.summon_card(CardInfo.from_name("L33pB0t"), sIdx, isFriendly)
