extends "res://scripts/classes/sigils/Waterborne.gd"

#Used for sigils that do something at the start of the turn
func start_of_turn(cardAnim):
	cardAnim.play("UnDive")
	var nTent = CardInfo.from_name(["Bell Tentacle", "Hand Tentacle", "Mirror Tentacle"][ (["Great Kraken", "Bell Tentacle", "Hand Tentacle", "Mirror Tentacle"].find(card.cardData.name)) % 3 ])
	
	var hp = card.health
	card.from_data(nTent)
	card.health = hp

	# Calculate
	slotManager.recalculate_buffs_and_such()
#	for fCard in slotManager.all_friendly_cards():
#		fCard.calculate_buffs()
#	for eCard in slotManager.all_enemy_cards():
#		eCard.calculate_buffs()

	# Hide tentacle atk symbol
	card.get_node("CardBody/AtkIcon").visible = false
	card.get_node("CardBody/AtkScore").visible = true
