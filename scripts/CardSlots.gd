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
	for slot in playerSlots:
		if slot.get_child_count() > 0:
			slot.get_child(0).queue_free()
	for slot in enemySlots:
		if slot.get_child_count() > 0:
			slot.get_child(0).queue_free()


# Sacrifice
func get_available_blood() -> int:
	var blood = 0
	
	for slot in playerSlots:
		if slot.get_child_count() > 0:
			if "Worthy Sacrifice" in slot.get_child(0).card_data["sigils"]:
				blood += 2
			blood += 1
	
	return blood

func get_available_slots() -> int:
	var freeSlots = 4
	
	for slot in playerSlots:
		if slot.get_child_count() > 0:
			freeSlots -= 1
	
	return freeSlots
	
func is_cat_bricked() -> bool:
	for slot in playerSlots:
		if slot.get_child_count() == 0:
			return false
		if not "Many Lives" in slot.get_child(0).card_data["sigils"]:
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
		if "Worthy Sacrifice" in victim.card_data["sigils"]:
			sacValue += 2

	if sacValue >= handManager.raisedCard.card_data["blood_cost"]:
		# Kill sacrifical victims
		for victim in sacVictims:
			if "Many Lives" in victim.card_data["sigils"]:
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
		
		# Evolution
		if "Fledgling" in card.card_data["sigils"]:
			rpc_id(fightManager.opponent, "remote_card_anim", slot.get_position_in_parent(), "Evolve")
			cardAnim.play("Evolve")
			yield (cardAnim, "animation_finished")
		
		# Dive
		if "Waterborne" in card.card_data["sigils"]:
			rpc_id(fightManager.opponent, "remote_card_anim", slot.get_position_in_parent(), "UnDive")
			cardAnim.play("UnDive")
			
	yield(get_tree().create_timer(0.01), "timeout")
	emit_signal("resolve_sigils")

func post_turn_sigils():
	var cardsToMove = []
	
	for slot in playerSlots:
		if slot.get_child_count() == 0:
			continue
		
		if slot.get_child(0).get_node("AnimationPlayer").is_playing():
			continue
		
		cardsToMove.append(slot.get_child(0))
	
	# Sprinting
	for card in cardsToMove:
		var cardAnim = card.get_node("AnimationPlayer")
		var cardTween = card.get_node("Tween")
		
		# Spront
		for movSigil in ["Sprinter", "Squirrel Shedder", "Skeleton Crew"]:
			if movSigil in card.card_data["sigils"] and not cardAnim.is_playing():
				
				var sprintSigil = card.get_node("CardBody/VBoxContainer/HBoxContainer").get_child(
					(card.card_data["sigils"].find(movSigil) * 2) + 1
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
	for slot in playerSlots:
		if slot.get_child_count() == 0:
			continue
		
		var card = slot.get_child(0)
		
		if card.get_node("AnimationPlayer").is_playing():
			continue
		
		if "Bone Digger" in card.card_data["sigils"]:
			fightManager.add_bones(1)
			fightManager.rpc_id(fightManager.opponent, "add_remote_bones", 1)
			rpc_id(fightManager.opponent, "remote_card_anim", card.get_parent().get_position_in_parent(), "ProcGeneric")
			card.get_node("AnimationPlayer").play("ProcGeneric")
			yield(card.get_node("AnimationPlayer"), "animation_finished")
		
		# Diving
		if "Waterborne" in card.card_data["sigils"]:
			rpc_id(fightManager.opponent, "remote_card_anim", card.get_parent().get_position_in_parent(), "Dive")
			card.get_node("AnimationPlayer").play("Dive")
			yield(card.get_node("AnimationPlayer"), "animation_finished")
			
	yield(get_tree().create_timer(0.01), "timeout")
	emit_signal("resolve_sigils")

# Combat
signal complete_combat()

func initiate_combat():
	for slot in playerSlots:
		if slot.get_child_count() > 0 and slot.get_child(0).attack > 0:
			
			var pCard = slot.get_child(0)
			var cardAnim = pCard.get_node("AnimationPlayer")
			var slot_index = slot.get_position_in_parent()
			
			
			if "Trifurcated Strike" in pCard.card_data["sigils"] or "Bifurcated Strike" in pCard.card_data["sigils"]:
				# Lower slot to right for attack anim (JANK AF)
				if slot_index < 3:
					playerSlots[slot_index + 1].show_behind_parent = true
				
				# Tri strike attack
				for s_offset in range(-1, 2):

					# Skip middle if bi-strike
					if s_offset == 0 and "Bifurcated Strike" in pCard.card_data["sigils"]:
						continue

					# Prevent attacking out of bounds
					var atk_slot = slot_index + s_offset
					if atk_slot < 0 or atk_slot > 3:
						continue
					
					# Don't attack repulsive cards!
					if enemySlots[slot_index + s_offset].get_child_count() > 0 and "Repulsive" in enemySlots[slot_index + s_offset].get_child(0).card_data["sigils"]:
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
				if enemySlots[slot_index].get_child_count() > 0 and "Repulsive" in enemySlots[slot_index].get_child(0).card_data["sigils"]:
					if not "Airborne" in pCard.card_data["sigils"] or "Mighty Leap" in enemySlots[slot_index].get_child(0).card_data["sigils"]:
						continue
				
				cardAnim.play("Attack")
				rpc_id(fightManager.opponent, "remote_card_anim", slot.get_position_in_parent(), "AttackRemote")
				yield(cardAnim, "animation_finished")
		
			# Any form of attack went through
			# Brittle: Die after attacking
			if "Brittle" in pCard.card_data["sigils"]:
				cardAnim.play("Perish")
				rpc_id(fightManager.opponent, "remote_card_anim", slot.get_position_in_parent(), "Perish")

	yield(get_tree().create_timer(0.01), "timeout")
	emit_signal("complete_combat")


# Do the attack damage
func handle_attack(from_slot, to_slot):
	var direct_attack = false
	
	var pCard = playerSlots[from_slot].get_child(0)
	var eCard = null
	
	if enemySlots[to_slot].get_child_count() == 0:
		direct_attack = true
	else:
		eCard = enemySlots[to_slot].get_child(0)
		if "Airborne" in pCard.card_data["sigils"] and not "Mighty Leap" in eCard.card_data["sigils"]:
			direct_attack = true
		if eCard.get_node("CardBody/DiveOlay").visible:
			direct_attack = true
	
	if direct_attack:
		fightManager.inflict_damage(pCard.attack)
	else:
		eCard.health -= pCard.attack
		eCard.draw_stats()
		if eCard.health <= 0 or "Touch of Death" in pCard.card_data["sigils"]:
			eCard.get_node("AnimationPlayer").play("Perish")
	
	rpc_id(fightManager.opponent, "handle_enemy_attack", from_slot, to_slot)

# Sigil handling
func get_friendly_card_sigil(sigil):
	for slot in playerSlots:
		if slot.get_child_count() > 0:
			if sigil in slot.get_child(0).card_data["sigils"]:
				return slot.get_child(0)
	
	return null

# Summon a card, used by Squirrel Ball
func summon_card(cDat, slot_idx):
	var nCard = fightManager.cardPrefab.instance()
	nCard.from_data(cDat)
	nCard.in_hand = false
	playerSlots[slot_idx].add_child(nCard)

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

remote func remote_card_move(from_slot, to_slot, flip_sigil):
	var eCard = enemySlots[from_slot].get_child(0)
	
	if from_slot != to_slot:
		eCard.move_to_parent(enemySlots[to_slot])
		
	if flip_sigil:
		var sigIdx = 0
		for sigil in eCard.card_data["sigils"]:
			if sigil in ["Sprinter", "Squirrel Shedder", "Skeleton Crew"]:
				var sig = eCard.get_node("CardBody/VBoxContainer/HBoxContainer").get_child(
					(sigIdx * 2) + 1
				)
				
				sig.flip_h = not sig.flip_h
			sigIdx += 1
				

remote func handle_enemy_attack(from_slot, to_slot):
	var direct_attack = false
	
	var eCard = enemySlots[from_slot].get_child(0)
	var pCard = null
	
	if playerSlots[to_slot].get_child_count() == 0:
		direct_attack = true
	else:
		pCard = playerSlots[to_slot].get_child(0)
		if "Airborne" in eCard.card_data["sigils"] and not "Mighty Leap" in pCard.card_data["sigils"]:
			direct_attack = true
		if pCard.get_node("CardBody/DiveOlay").visible:
			direct_attack = true
	
	if direct_attack:
		fightManager.inflict_damage(-eCard.attack)
	else:
		pCard.health -= eCard.attack
		pCard.draw_stats()
		if pCard.health <= 0 or "Touch of Death" in eCard.card_data["sigils"]:
			pCard.get_node("AnimationPlayer").play("Perish")

# Something for tri strike effect
remote func set_card_offset(card_slot, offset):
	if card_slot < 3:
		if offset > 0:
			enemySlots[card_slot + 1].show_behind_parent = true
		else:
			enemySlots[card_slot + 1].show_behind_parent = false
	
	enemySlots[card_slot].get_child(0).rect_position.x = offset
