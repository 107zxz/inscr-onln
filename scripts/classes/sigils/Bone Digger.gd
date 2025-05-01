extends SigilEffect

#Used for sigils that do something at the end of the turn
#ex: Waterborne (cosmetic), Bone Digger
func end_of_turn(card_anim):
	fightManager.add_bones(1) if is_friendly else fightManager.add_opponent_bones(1)
	card_anim.play("ProcGeneric")
	yield(card_anim, "animation_finished")
