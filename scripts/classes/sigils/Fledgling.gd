extends SigilEffect

#Used for sigils that do something at the start of the turn
func start_of_turn(cardAnim):
	cardAnim.play("Evolve")
	yield (cardAnim, "animation_finished")
	var dmgTaken = card.cardData["health"] - card.health
	card.from_data(CardInfo.from_name(card.cardData["evolution"]))
	card.health = card.cardData["health"] - dmgTaken
	# Calculate buffs
	slotManager.recalculate_buffs_and_such()
#	for card in slotManager.all_friendly_cards():
#		card.calculate_buffs()
#	for eCard in slotManager.all_enemy_cards():
#		eCard.calculate_buffs()

	
