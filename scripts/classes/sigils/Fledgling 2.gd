extends SigilEffect

#Used for sigils that do something at the start of the turn
func start_of_turn(cardAnim):
	cardAnim.play("Evolve")
	yield (cardAnim, "animation_finished")

	# Deep copy
	var dmgTaken = card.cardData["health"] - card.health
	var new_sigs: Array = card.cardData.sigils.duplicate()
	new_sigs.erase("Fledgling 2")
	new_sigs.append("Fledgling")
	card.cardData.sigils = new_sigs
	card.from_data(card.cardData)
	card.health = card.cardData["health"] - dmgTaken
	
	slotManager.recalculate_buffs_and_such()
#	for fcard in slotManager.all_friendly_cards():
#		fcard.calculate_buffs()
#	for eCard in slotManager.all_enemy_cards():
#		eCard.calculate_buffs()


	

