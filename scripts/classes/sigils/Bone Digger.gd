extends SigilEffect

#Used for sigils that do something at the end of the turn
#ex: Waterborne (cosmetic), Bone Digger
func end_of_turn(cardAnim):
	fightManager.add_bones(1) if isFriendly else fightManager.add_opponent_bones(1)
	cardAnim.play("ProcGeneric")
	yield(cardAnim, "animation_finished")
