extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):
	
	if card.get_parent().name == "PlayerHand":
		return
	
	var oFriendly = params[0].get_parent().get_parent().name == "PlayerSlots"
	
	if event == "card_perished" and isFriendly != oFriendly:

		if isFriendly:	
			fightManager.add_bones(1)
		else:
			fightManager.add_opponent_bones(1)
