extends SigilEffect

#Used for sigils that do something at the start of the turn
func start_of_turn(card_anim):
	card_anim.play("Evolve")
	yield (card_anim, "animation_finished")
	var dmgTaken = card.card_data["health"] - card.health
	card.from_data(CardInfo.from_name(card.card_data["evolution"]))
	card.health = card.card_data["health"] - dmgTaken
	# Calculate buffs
	slotManager.recalculate_buffs_and_such()
#	for card in slotManager.all_friendly_cards():
#		card.calculate_buffs()
#	for eCard in slotManager.all_enemy_cards():
#		eCard.calculate_buffs()

	
