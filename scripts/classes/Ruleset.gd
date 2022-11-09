class_name Ruleset

var cards = []
var sigils = {}

func from_name(nm):
	for card in cards:
		if card.name == nm:
			return card
	return false

func _init():
	
	cards = CardInfo.all_cards
	
	return self
