extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_summoned" and params[0] == card:
		print("Royal Defender triggered!")
		
		# in THEORY this should still be linked since it's not duplicated
		var tribeSigils:Dictionary = (slotManager.friendlyTribeSigils if isFriendly else slotManager.enemyTribeSigils)
		
		if not tribeSigils.has("Royal"):
			tribeSigils["Royal"] = {}
		
		tribeSigils["Royal"]["Invincible"] = tribeSigils["Royal"].get("Invincible", 0) + 1
		
		if isFriendly:
			print("friendly", slotManager.friendlyTribeSigils)
		else:
			print("enemy", slotManager.enemyTribeSigils)
		return
	
	elif event == "card_perished" and params[0] == card:
		var tribeSigils:Dictionary = (slotManager.friendlyTribeSigils if isFriendly else slotManager.enemyTribeSigils)
		
		# this should still be there
		tribeSigils["Royal"]["Invincible"] -= 1
		
		# cleanup
		if tribeSigils["Royal"]["Invincible"] <= 0:
			tribeSigils["Royal"].erase("Invincible")
		
		return
