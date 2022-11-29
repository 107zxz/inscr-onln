extends VBoxContainer

# The currently raised card. A raised card is a card selected for play
var raisedCard = null
var opponentRaisedCard = null

func lower_all_cards():
	for card in $PlayerHand.get_children():
		card.lower()
	
	raisedCard = null

func clear_hands():
	for hand in get_children():
		
		print("Wiping ", hand.name)
		
		for bcard in hand.get_children():
			bcard.queue_free()
			
# Remote functions
func raise_opponent_card(index):
	opponentRaisedCard = $EnemyHand.get_child(index)
	opponentRaisedCard.get_node("AnimationPlayer").play("Raise")
	yield(opponentRaisedCard.get_node("AnimationPlayer"), "animation_finished")
	get_node("/root/Main/CardFight").move_done()
	
func lower_opponent_card(index):
	# This will be called if the enemy just played a card, in this case, consider the card lowered but don't play an animation
	if $EnemyHand.get_child_count() > index and $EnemyHand.get_child(index) == opponentRaisedCard:
		opponentRaisedCard.get_node("AnimationPlayer").play("Lower")
	
		yield(opponentRaisedCard.get_node("AnimationPlayer"), "animation_finished")
		get_node("/root/Main/CardFight").move_done()
		return
		
	opponentRaisedCard = null
	get_node("/root/Main/CardFight").move_done()

