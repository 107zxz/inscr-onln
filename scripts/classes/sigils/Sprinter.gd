extends SigilEffect

var sprintSigil = null

func end_of_turn(cardAnim):
	var cardTween = card.get_node("Tween")
	
	#janky ass way to find the actual sigil object, which we need to flip occasionally
	#cached because it's probably a good idea
	if not sprintSigil:
		var name = get_script().resource_path.get_file()
		name = name.left(name.length() - 3)
		sprintSigil = card.get_node("CardBody/Sigils/Row1").get_child(
			card.card_data["sigils"].find(name)
		)
	
	var curSlot = card.get_parent().get_position_in_parent()
	var sprintOffset = -1 if sprintSigil.flip_h else 1
	var moveFailed = false
	var cantMove = false
	var affectedSlots = slotManager.playerSlots if isFriendly else slotManager.enemySlots
	
	for _i in range(2):
		# Edges of screen
		if curSlot + sprintOffset > 3:
			if moveFailed:
				cantMove = true
				break
			sprintSigil.flip_h = true
			moveFailed = true
		elif curSlot + sprintOffset < 0:
			if moveFailed:
				cantMove = true
				break
			sprintSigil.flip_h = false
			moveFailed = true

		# Occupied slots
		elif not slotManager.is_slot_empty(affectedSlots[curSlot + sprintOffset]): # and not affectedSlots[curSlot + sprintOffset].get_child(0).get_node("AnimationPlayer").is_playing():

			if can_push():

				var pushed = false

				if curSlot + sprintOffset * 2 <= 3 and curSlot + sprintOffset * 2 >= 0:
					if slotManager.is_slot_empty(affectedSlots[curSlot + sprintOffset * 2]): # or affectedSlots[curSlot + sprintOffset * 2].get_child(0).get_node("AnimationPlayer").is_playing():
						affectedSlots[curSlot + sprintOffset].get_child(0).move_to_parent(affectedSlots[curSlot + sprintOffset * 2])
						pushed = true

					elif curSlot + sprintOffset * 3 <= 3 and curSlot + sprintOffset * 3 >= 0:
						if slotManager.is_slot_empty(affectedSlots[curSlot + sprintOffset * 3]): # or affectedSlots[curSlot + sprintOffset * 3].get_child(0).get_node("AnimationPlayer").is_playing():
							affectedSlots[curSlot + sprintOffset].get_child(0).move_to_parent(affectedSlots[curSlot + sprintOffset * 2])
							affectedSlots[curSlot + sprintOffset * 2].get_child(0).move_to_parent(affectedSlots[curSlot + sprintOffset * 3])
							pushed = true

				if pushed:
					# A push has happened, recalculate stats
					for fCard in slotManager.all_friendly_cards():
						fCard.calculate_buffs()
					for eCard in slotManager.all_enemy_cards():
						eCard.calculate_buffs()
				else:
					if moveFailed:
						cantMove = true
						break
					sprintSigil.flip_h = not sprintSigil.flip_h
					moveFailed = true
			else:
				if moveFailed:
					cantMove = true
					break
				sprintSigil.flip_h = not sprintSigil.flip_h
				moveFailed = true

		sprintOffset = -1 if sprintSigil.flip_h else 1

	if cantMove:
		sprintOffset = 0
	else:
		on_move(curSlot)

		card.move_to_parent(affectedSlots[curSlot + sprintOffset])


		# A push has happened, recalculate stats
		for fCard in slotManager.all_friendly_cards():
			fCard.calculate_buffs()
		for eCard in slotManager.all_enemy_cards():
			eCard.calculate_buffs()

	# Wait for move to finish
		yield (cardTween, "tween_completed")


#Should I include the code for pusing in the default sprint sigil? idk. Am I going to? Yes, because it makes my life easier, as well as probably everyone elses.
func can_push():
	return false

func on_move(curSlot):
	pass
