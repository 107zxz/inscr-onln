extends SigilEffect

#Used for sigils that passively define the power of the card they're attached to, such as Ant, Spilled Blood, etc...
func define_power():
	var hName = "PlayerHand" if isFriendly else "EnemyHand"
	return fightManager.get_node("HandsContainer/Hands/" + hName).get_child_count()

#IMPORTANT: replace this with 'return true' for any sigil that sets the user's Power/Attack. Returns false otherwise, as a card can only have one of these at once. 
func is_power_defining():
	return true
