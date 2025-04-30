extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# Was card summoned / moved to the space opposing this one?
	
	# On the board
	if not card.inHand:
		if event in ["card_summoned", "card_moved"]:
			# Fuck necromancer. All my homies hate necromancer
			if params[0].get_node("AnimationPlayer").current_animation == "DoublePerish":
				return
				
			# Cannot see if dead or double dead
			if card.get_node("AnimationPlayer").current_animation != "Perish" \
			and card.get_node("AnimationPlayer").current_animation != "DoublePerish":
				
				if params[0] == card and event == "card_moved":
					hit_and_run(params)
				else:
					normal_behaviour(params)

func normal_behaviour(params: Array):
	# Target card must be in opposing spaces
	if params[0].get_parent().get_parent() == card.get_parent().get_parent():
		return
	
	# Target card must be in same slot
	if params[0].slot_idx() != card.slot_idx():
		return
	
	params[0].take_damage(card, 1)


func hit_and_run(params: Array):
	var opposing_card = \
		slotManager.get_enemy_card(card.slot_idx()) if isFriendly \
		else slotManager.get_friendly_card(card.slot_idx())
	
	if opposing_card:
		opposing_card.take_damage(card, 1)
