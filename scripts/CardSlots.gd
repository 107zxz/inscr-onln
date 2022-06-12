extends VBoxContainer


onready var playerSlots = $PlayerSlots.get_children()
onready var enemySlots = $EnemySlots.get_children()
onready var fightManager = get_node("/root/Main/CardFight")
onready var handManager = fightManager.get_node("HandsContainer/Hands")
onready var allCards = get_node("/root/Main/AllCards")

# Cards selected for sacrifice
var sacVictims = []


# Board interactions
func clear_slots():
	for card in all_friendly_cards():
		card.queue_free()
	for card in all_enemy_cards():
		card.queue_free()

# Sacrifice
func get_available_blood() -> int:
	var blood = 0
	
	for card in all_friendly_cards():
		if card.has_sigil("Worthy Sacrifice"):
			blood += 2
		# Don't allow saccing mox cards
		if "nosac" in card.card_data:
			continue
		blood += 1
	
	return blood

func get_available_slots() -> int:
	var freeSlots = 4
	
	for _card in all_friendly_cards():
		freeSlots -= 1
	
	return freeSlots
	
func is_cat_bricked() -> bool:
	if get_available_slots():
		return false

	for card in all_friendly_cards():
		if not card.has_sigil("Many Lives"):
			return false
	
	return true

func clear_sacrifices():
	for victim in sacVictims:
		victim.get_node("CardBody/SacOlay").visible = false
		rpc_id(fightManager.opponent, "set_sac_olay_vis", victim.get_parent().get_position_in_parent(), false)
	
	sacVictims.clear()

func attempt_sacrifice():

	var sacValue = 0

	for victim in sacVictims:
		sacValue += 1
		if victim.has_sigil("Worthy Sacrifice"):
			sacValue += 2

	if sacValue >= handManager.raisedCard.card_data["blood_cost"]:
		# Kill sacrifical victims
		for victim in sacVictims:
			if victim.has_sigil("Many Lives"):
				victim.get_node("AnimationPlayer").play("CatSac")
				rpc_id(fightManager.opponent, "remote_card_anim", victim.get_parent().get_position_in_parent(), "CatSac")
			else:
				victim.get_node("AnimationPlayer").play("Perish")
				rpc_id(fightManager.opponent, "remote_card_anim", victim.get_parent().get_position_in_parent(), "Perish")
				
			
		sacVictims.clear()
		
		# Force player to summon the new card
		fightManager.state = fightManager.GameStates.FORCEPLAY

# Break flow to handle sigils
signal resolve_sigils()

func pre_turn_sigils():
	for slot in playerSlots:
		if slot.get_child_count() == 0:
			continue
		
		var card = slot.get_child(0)
		var cardAnim = card.get_node("AnimationPlayer")
		
		if cardAnim.is_playing():
			continue
		
		if false and "active" in card.card_data:
			var cd = card.get_node("CardBody/VBoxContainer/HBoxContainer/ActiveSigil")
			cd.disabled = false
			cd.mouse_filter = MOUSE_FILTER_STOP
		
		# Evolution
		if card.has_sigil("Fledgling"):
			rpc_id(fightManager.opponent, "remote_card_anim", slot.get_position_in_parent(), "Evolve")
			cardAnim.play("Evolve")
			yield (cardAnim, "animation_finished")
			
		# Dive
		if card.has_sigil("Waterborne"):
			rpc_id(fightManager.opponent, "remote_card_anim", slot.get_position_in_parent(), "UnDive")
			cardAnim.play("UnDive")
			
	yield(get_tree().create_timer(0.01), "timeout")
	emit_signal("resolve_sigils")

func post_turn_sigils():
	var cardsToMove = []
	
	for slot in playerSlots:
		if slot.get_child_count() == 0:
			continue
		
		if "Perish" in slot.get_child(0).get_node("AnimationPlayer").current_animation:
			continue
		
		cardsToMove.append(slot.get_child(0))
	
	# Sprinting
	for card in cardsToMove:
		var cardAnim = card.get_node("AnimationPlayer")
		var cardTween = card.get_node("Tween")
		
		# Spront
		for movSigil in ["Sprinter", "Squirrel Shedder", "Skeleton Crew", "Hefty"]:
			if card.has_sigil(movSigil) and not "Perish" in cardAnim.current_animation:
				
				var sprintSigil = card.get_node("CardBody/VBoxContainer/HBoxContainer").get_child(
					2 if card.card_data["sigils"].find(movSigil) == 0 else 4
				)
				
				var curSlot = card.get_parent().get_position_in_parent()
				
				var oSprintOffset = -1 if sprintSigil.flip_h else 1
				var sprintOffset = oSprintOffset
				var moveFailed = false
				var cantMove = false
				var ogFlipped = sprintSigil.flip_h
				
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
					elif playerSlots[curSlot + sprintOffset].get_child_count() > 0 and not playerSlots[curSlot + sprintOffset].get_child(0).get_node("AnimationPlayer").is_playing():

						if movSigil == "Hefty":

							var pushed = false

							if curSlot + sprintOffset * 2 <= 3 and curSlot + sprintOffset * 2 >= 0:
								if playerSlots[curSlot + sprintOffset * 2].get_child_count() == 0 or playerSlots[curSlot + sprintOffset * 2].get_child(0).get_node("AnimationPlayer").is_playing():
									playerSlots[curSlot + sprintOffset].get_child(0).move_to_parent(playerSlots[curSlot + sprintOffset * 2])
									rpc_id(
									fightManager.opponent, "remote_card_move", 
									curSlot + sprintOffset,
									curSlot + sprintOffset * 2,
									false
									)
									pushed = true
							
								elif curSlot + sprintOffset * 3 <= 3 and curSlot + sprintOffset * 3 >= 0:
									if playerSlots[curSlot + sprintOffset * 3].get_child_count() == 0 or playerSlots[curSlot + sprintOffset * 3].get_child(0).get_node("AnimationPlayer").is_playing():
										playerSlots[curSlot + sprintOffset].get_child(0).move_to_parent(playerSlots[curSlot + sprintOffset * 2])
										rpc_id(
										fightManager.opponent, "remote_card_move", 
										curSlot + sprintOffset,
										curSlot + sprintOffset * 2,
										false
										)
										playerSlots[curSlot + sprintOffset * 2].get_child(0).move_to_parent(playerSlots[curSlot + sprintOffset * 3])
										rpc_id(
										fightManager.opponent, "remote_card_move", 
										curSlot + sprintOffset * 2,
										curSlot + sprintOffset * 3,
										false
										)
										pushed = true
							
							if not pushed:
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
					# Spawn a card if thats the one
					if movSigil == "Squirrel Shedder":
						summon_card(allCards.all_cards[29], curSlot)
						rpc_id(fightManager.opponent, "remote_card_summon", allCards.all_cards[29], curSlot)
					if movSigil == "Skeleton Crew":
						summon_card(allCards.all_cards[78], curSlot)
						rpc_id(fightManager.opponent, "remote_card_summon", allCards.all_cards[78], curSlot)
						
				card.move_to_parent(playerSlots[curSlot + sprintOffset])
				rpc_id(
					fightManager.opponent, "remote_card_move", 
					curSlot,
					curSlot + sprintOffset,
					sprintSigil.flip_h != ogFlipped
					)
				
				# Wait for move to finish
				yield (cardTween, "tween_completed")
	
	# Other end-of-turn sigils
	for card in all_friendly_cards():
		if card.get_node("AnimationPlayer").is_playing():
			continue
		
		if card.has_sigil("Bone Digger"):
			fightManager.add_bones(1)
			fightManager.rpc_id(fightManager.opponent, "add_remote_bones", 1)
			rpc_id(fightManager.opponent, "remote_card_anim", card.get_parent().get_position_in_parent(), "ProcGeneric")
			card.get_node("AnimationPlayer").play("ProcGeneric")
			yield(card.get_node("AnimationPlayer"), "animation_finished")
		
		# Diving
		if card.has_sigil("Waterborne"):
			rpc_id(fightManager.opponent, "remote_card_anim", card.get_parent().get_position_in_parent(), "Dive")
			card.get_node("AnimationPlayer").play("Dive")
			yield(card.get_node("AnimationPlayer"), "animation_finished")
			
	yield(get_tree().create_timer(0.01), "timeout")
	emit_signal("resolve_sigils")

# Combat
signal complete_combat()

func initiate_combat():
	for card in all_friendly_cards():
		if card.attack > 0 and not "Perish" in card.get_node("AnimationPlayer").current_animation:
			
			var pCard = card
			var cardAnim = pCard.get_node("AnimationPlayer")
			var slot_index = card.slot_idx()
			
			
			if pCard.has_sigil("Trifurcated Strike") or pCard.has_sigil("Bifurcated Strike"):
				# Lower slot to right for attack anim (JANK AF)
				if slot_index < 3:
					playerSlots[slot_index + 1].show_behind_parent = true
				
				# Tri strike attack
				for s_offset in range(-1, 2):

					# Skip middle if bi-strike
					if s_offset == 0 and pCard.has_sigil("Bifurcated Strike"):
						continue

					# Prevent attacking out of bounds
					var atk_slot = slot_index + s_offset
					if atk_slot < 0 or atk_slot > 3:
						continue
					
					# Don't attack repulsive cards!
					if enemySlots[slot_index + s_offset].get_child_count() > 0 and enemySlots[slot_index + s_offset].get_child(0).has_sigil("Repulsive"):
						continue
					
					# Visually represent the card's attack offset (hacky)
					pCard.rect_position.x = s_offset * 50
					rpc_id(fightManager.opponent, "set_card_offset", slot_index, s_offset * 50)
					
					pCard.strike_offset = s_offset
					cardAnim.play("Attack")
					rpc_id(fightManager.opponent, "remote_card_anim", slot_index, "AttackRemote")
					yield(cardAnim, "animation_finished")
				
				# Reset attack effect
				if slot_index < 3:
					playerSlots[slot_index + 1].show_behind_parent = false
				pCard.rect_position.x = 0
				rpc_id(fightManager.opponent, "set_card_offset", slot_index, 0)
			else:
				# Regular attack
				
				# Don't attack repulsive cards!
				if enemySlots[slot_index].get_child_count() > 0 and enemySlots[slot_index].get_child(0).has_sigil("Repulsive"):
					if not pCard.has_sigil("Airborne") or enemySlots[slot_index].get_child(0).has_sigil("Mighty Leap"):
						continue
				
				cardAnim.play("Attack")
				rpc_id(fightManager.opponent, "remote_card_anim", slot_index, "AttackRemote")
				yield(cardAnim, "animation_finished")
		
			# Any form of attack went through
			# Brittle: Die after attacking
			if pCard.has_sigil("Brittle"):
				cardAnim.play("Perish")
				rpc_id(fightManager.opponent, "remote_card_anim", slot_index, "Perish")

	yield(get_tree().create_timer(0.01), "timeout")
	emit_signal("complete_combat")


# Do the attack damage
func handle_attack(from_slot, to_slot):
	var direct_attack = false
	
	var pCard = playerSlots[from_slot].get_child(0)
	var eCard = null
	
	if enemySlots[to_slot].get_child_count() == 0:
		direct_attack = true

		# Check for moles
		# Mole man
		if pCard.has_sigil("Airborne"):
			for card in all_enemy_cards():
				if card.has_sigil("Burrower") and card.has_sigil("Mighty Leap"):
					direct_attack = false
					card.move_to_parent(enemySlots[to_slot])
					eCard = card
		else: # Regular mole
			for card in all_enemy_cards():
				if card.has_sigil("Burrower"):
					direct_attack = false
					card.move_to_parent(enemySlots[to_slot])
					eCard = card

	else:
		eCard = enemySlots[to_slot].get_child(0)
		if pCard.has_sigil("Airborne") and not eCard.has_sigil("Mighty Leap"):
			direct_attack = true
		if eCard.get_node("CardBody/DiveOlay").visible:
			direct_attack = true
	
	if direct_attack:
		

		fightManager.inflict_damage(pCard.attack)

		# Looter
		if pCard.has_sigil("Looter"):
			for _i in range(pCard.attack):
				if fightManager.deck.size() == 0:
					break
					
				fightManager.draw_card(fightManager.deck.pop_front())
		
				# Some interaction here if your deck has less than 3 cards. Don't punish I guess?
				if fightManager.deck.size() == 0:
					get_node("../DrawPiles/YourDecks/Deck").visible = false
					break
	else:
		eCard.health -= pCard.attack
		eCard.draw_stats()
		if eCard.health <= 0 or pCard.has_sigil("Touch of Death"):
			eCard.get_node("AnimationPlayer").play("Perish")
		
		# Sharp quills
		if eCard.has_sigil("Sharp Quills"):
			pCard.health -= 1
			pCard.draw_stats()
			if pCard.health <= 0 or eCard.has_sigil("Touch of Death"):
				pCard.get_node("AnimationPlayer").play("Perish")
		
	
	rpc_id(fightManager.opponent, "handle_enemy_attack", from_slot, to_slot)

# Sigil handling
func get_friendly_cards_sigil(sigil):
	var found = []

	for card in all_friendly_cards():
		if card.has_sigil(sigil):
			found.append(card)
	
	return found

func get_enemy_cards_sigil(sigil):
	var found = []

	for card in all_enemy_cards():
		if card.has_sigil(sigil):
			found.append(card)
	
	return found

# Summon a card, used by Squirrel Ball
func summon_card(cDat, slot_idx):
	var nCard = fightManager.cardPrefab.instance()
	nCard.from_data(cDat)
	nCard.in_hand = false
	playerSlots[slot_idx].add_child(nCard)
	
	fightManager.card_summoned(nCard)

# Remote
remote func set_sac_olay_vis(slot, vis):
	enemySlots[slot].get_child(0).get_node("CardBody/SacOlay").visible = vis

remote func remote_card_anim(slot, anim_name):
	enemySlots[slot].get_child(0).get_node("AnimationPlayer").stop()
	enemySlots[slot].get_child(0).get_node("AnimationPlayer").play(anim_name)

remote func remote_card_summon(cDat, slot_idx):
	var nCard = fightManager.cardPrefab.instance()
	nCard.from_data(cDat)
	nCard.in_hand = false
	enemySlots[slot_idx].add_child(nCard)


remote func remote_activate_sigil(card_slot, arg = 0):
	var eCard = enemySlots[card_slot].get_child(0)
	var sName = eCard.card_data["sigils"][0]
	
	if sName == "True Scholar":
		eCard.get_node("AnimationPlayer").play("Perish")
		return
	
	if sName == "Energy Gun":
		
		var pCard = playerSlots[card_slot].get_child(0)
		fightManager.set_opponent_energy(fightManager.opponent_energy - 1)
		
		pCard.health -= 1
		if pCard.health <= 0:
			pCard.get_node("AnimationPlayer").play("Perish")
		else:
			pCard.draw_stats()
	
	if sName == "Power Dice":
		fightManager.set_opponent_energy(fightManager.opponent_energy - 1)
		
		eCard.attack = arg
		eCard.draw_stats()
	
	if sName == "Enlarge":
		fightManager.add_opponent_bones(-2)
		eCard.health += 1
		eCard.attack += 1
		eCard.draw_stats()
	
	if sName == "Stimulate":
		fightManager.set_opponent_energy(fightManager.opponent_energy - 3)
		eCard.health += 1
		eCard.attack += 1
		eCard.draw_stats()
	
	if sName == "Disentomb":
		fightManager.add_opponent_bones(-1)
	
	eCard.get_node("AnimationPlayer").play("ProcGeneric")


remote func remote_card_move(from_slot, to_slot, flip_sigil):
	var eCard = enemySlots[from_slot].get_child(0)
	
	if from_slot != to_slot:
		eCard.move_to_parent(enemySlots[to_slot])
		
	if flip_sigil:
		for sigil in eCard.card_data["sigils"]:
			if sigil in ["Sprinter", "Squirrel Shedder", "Skeleton Crew", "Hefty"]:
				var sig = eCard.get_node("CardBody/VBoxContainer/HBoxContainer").get_child(
					2 if eCard.card_data["sigils"].find(sigil) == 0 else 4
				)
				
				sig.flip_h = not sig.flip_h

remote func remote_card_stats(card_slot, new_attack, new_health):
	var card = get_enemy_card(card_slot)
	card.attack = new_attack if new_attack != null else card.attack
	card.health = new_health if new_health != null else card.health
	card.draw_stats()

remote func handle_enemy_attack(from_slot, to_slot):
	var direct_attack = false
	
	var eCard = get_enemy_card(from_slot)
	var pCard = null
	
	if playerSlots[to_slot].get_child_count() == 0:
		direct_attack = true

		# Check for moles
		# Mole man
		if eCard.has_sigil("Airborne"):
			for card in all_friendly_cards():
				if card.has_sigil("Burrower") and card.has_sigil("Mighty Leap"):
					direct_attack = false
					card.move_to_parent(playerSlots[to_slot])
					pCard = card
		else: # Regular mole
			for card in all_friendly_cards():
				if card.has_sigil("Burrower"):
					direct_attack = false
					card.move_to_parent(playerSlots[to_slot])
					pCard = card
	else:
		pCard = playerSlots[to_slot].get_child(0)
		if eCard.has_sigil("Airborne") and not pCard.has_sigil("Mighty Leap"):
			direct_attack = true
		if pCard.get_node("CardBody/DiveOlay").visible:
			direct_attack = true
	
	if direct_attack:
		fightManager.inflict_damage(-eCard.attack)
	else:
		pCard.health -= eCard.attack
		pCard.draw_stats()
		if pCard.health <= 0 or eCard.has_sigil("Touch of Death"):
			pCard.get_node("AnimationPlayer").play("Perish")
		
		# Sharp quills
		if pCard.has_sigil("Sharp Quills"):
			eCard.health -= 1
			eCard.draw_stats()
			if eCard.health <= 0 or "Touch of Death" in pCard.has_sigil("Touch of Death"):
				eCard.get_node("AnimationPlayer").play("Perish")

# Something for tri strike effect
remote func set_card_offset(card_slot, offset):
	if card_slot < 3:
		if offset > 0:
			enemySlots[card_slot + 1].show_behind_parent = true
		else:
			enemySlots[card_slot + 1].show_behind_parent = false
	
	enemySlots[card_slot].get_child(0).rect_position.x = offset


# New Helper functions
func get_friendly_card(slot_idx):
	for card in playerSlots[slot_idx].get_children():
		if not "Perish" in card.get_node("AnimationPlayer").current_animation:
			return card
	return false

func get_enemy_card(slot_idx):
	for card in enemySlots[slot_idx].get_children():
		if not "Perish" in card.get_node("AnimationPlayer").current_animation:
			return card
	return false

func all_friendly_cards():
	var cards = []

	for slot in playerSlots:
		if slot.get_child_count() and not "Perish" in slot.get_child(0).get_node("AnimationPlayer").current_animation:
			cards.append(slot.get_child(0))
	
	return cards

func all_enemy_cards():
	var cards = []

	for slot in enemySlots:
		if slot.get_child_count() and not "Perish" in slot.get_child(0).get_node("AnimationPlayer").current_animation:
			cards.append(slot.get_child(0))
	
	return cards
