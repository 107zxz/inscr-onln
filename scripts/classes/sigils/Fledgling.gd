extends SigilEffect

func start_of_turn(cardAnim):
	cardAnim.play("Evolve")
	yield (cardAnim, "animation_finished")
	var dmgTaken = card.card_data["health"] - card.health
	card.from_data(CardInfo.from_name(card.card_data["evolution"]))
	card.health = card.card_data["health"] - dmgTaken
	# Calculate buffs
	for card in slotManager.all_friendly_cards():
		card.calculate_buffs()
	for eCard in slotManager.all_enemy_cards():
		eCard.calculate_buffs()

	
