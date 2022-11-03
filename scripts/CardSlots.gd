extends Control

onready var playerSlots = $PlayerSlots.get_children()
onready var enemySlots = $EnemySlots.get_children()
onready var fightManager = get_node("/root/Main/CardFight")
onready var handManager = fightManager.get_node("HandsContainer/Hands")

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
		if card.has_sigil("Noble Sacrifice"):
			blood += 1
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

func get_hammerable_cards():
	var nCards = 0
	
	for card in all_friendly_cards():
		if not "nohammer" in card.card_data:
			nCards += 1
	
	return nCards

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
		if victim.has_sigil("Noble Sacrifice"):
			sacValue += 1

	if sacValue >= handManager.raisedCard.card_data["blood_cost"]:
		# Kill sacrifical victims
		for victim in sacVictims:
			if victim.has_sigil("Many Lives"):
				victim.get_node("AnimationPlayer").play("CatSac")
				rpc_id(fightManager.opponent, "remote_card_anim", victim.slot_idx(), "CatSac")
				victim.sacrifice_count += 1
				
				# Undeadd cat
				if victim.card_data["name"] == "Cat" and victim.sacrifice_count == 9:
					victim.from_data(CardInfo.from_name("Undead Cat"))
					rpc_id(fightManager.opponent, "remote_card_data", victim.slot_idx(), CardInfo.from_name("Undead Cat"))
				# Pets to cat
				if victim.card_data["name"] == "Pharaoh's Pets" and handManager.raisedCard.card_data["blood_cost"] > sacValue - 2:
					victim.from_data(CardInfo.from_name("Cat"))
					rpc_id(fightManager.opponent, "remote_card_data", victim.slot_idx(), CardInfo.from_name("Cat"))

			else:
				victim.get_node("AnimationPlayer").play("Perish")
				rpc_id(fightManager.opponent, "remote_card_anim", victim.slot_idx(), "Perish")
				
			
		sacVictims.clear()
		
		# Force player to summon the new card
		fightManager.state = fightManager.GameStates.FORCEPLAY

# Break flow to handle sigils
signal resolve_sigils()

func pre_turn_sigils(friendly: bool):
	
	var affectedSlots = playerSlots if friendly else enemySlots
	
	for slot in affectedSlots:
		if is_slot_empty(slot):
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
#			rpc_id(fightManager.opponent, "remote_card_anim", slot.get_position_in_parent(), "Evolve")
			cardAnim.play("Evolve")
			yield (cardAnim, "animation_finished")
			
		# Dive
		if card.has_sigil("Waterborne") or card.has_sigil("Tentacle"):
#			rpc_id(fightManager.opponent, "remote_card_anim", slot.get_position_in_parent(), "UnDive")
			cardAnim.play("UnDive")

			if card.has_sigil("Tentacle"):
				var nTent = CardInfo.from_name(["Bell Tentacle", "Hand Tentacle", "Mirror Tentacle"][ (["Great Kraken", "Bell Tentacle", "Hand Tentacle", "Mirror Tentacle"].find(card.card_data.name)) % 3 ])
				card.from_data(nTent)
#				rpc_id(fightManager.opponent, "remote_card_data", slot.get_position_in_parent(), nTent)
			
				# Calculate
				for fCard in all_friendly_cards():
					fCard.calculate_buffs()
				for eCard in all_enemy_cards():
					eCard.calculate_buffs()
				
				# Hide tentacle atk symbol
				card.get_node("CardBody/AtkIcon").visible = false
				card.get_node("CardBody/HBoxContainer/AtkScore").visible = true

	# Enemy spawn conduit
	if get_enemy_cards_sigil("Spawn Conduit") and friendly:
		print("Spawn Conduit ENEMY")
		print(friendly)
		for sIdx in range(4):
			if is_slot_empty(enemySlots[sIdx]) and "Spawn Conduit" in get_conduitfx_enemy(sIdx):
				summon_card(CardInfo.from_name("L33pB0t"), sIdx, false)


	yield(get_tree().create_timer(0.01), "timeout")
	emit_signal("resolve_sigils")

func post_turn_sigils(friendly: bool):
	var cardsToMove = all_friendly_cards() if friendly else all_enemy_cards()
	
	var affectedSlots = playerSlots if friendly else enemySlots
	
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
				
				var sprintOffset = -1 if sprintSigil.flip_h else 1
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
					elif not is_slot_empty(affectedSlots[curSlot + sprintOffset]) and not affectedSlots[curSlot + sprintOffset].get_child(0).get_node("AnimationPlayer").is_playing():

						if movSigil == "Hefty":

							var pushed = false

							if curSlot + sprintOffset * 2 <= 3 and curSlot + sprintOffset * 2 >= 0:
								if is_slot_empty(affectedSlots[curSlot + sprintOffset * 2]) or affectedSlots[curSlot + sprintOffset * 2].get_child(0).get_node("AnimationPlayer").is_playing():
									affectedSlots[curSlot + sprintOffset].get_child(0).move_to_parent(affectedSlots[curSlot + sprintOffset * 2])
#									rpc_id(
#									fightManager.opponent, "remote_card_move", 
#									curSlot + sprintOffset,
#									curSlot + sprintOffset * 2,
#									false
#									)
									pushed = true
							
								elif curSlot + sprintOffset * 3 <= 3 and curSlot + sprintOffset * 3 >= 0:
									if is_slot_empty(affectedSlots[curSlot + sprintOffset * 3]) or affectedSlots[curSlot + sprintOffset * 3].get_child(0).get_node("AnimationPlayer").is_playing():
										affectedSlots[curSlot + sprintOffset].get_child(0).move_to_parent(affectedSlots[curSlot + sprintOffset * 2])
#										rpc_id(
#										fightManager.opponent, "remote_card_move", 
#										curSlot + sprintOffset,
#										curSlot + sprintOffset * 2,
#										false
#										)
										affectedSlots[curSlot + sprintOffset * 2].get_child(0).move_to_parent(affectedSlots[curSlot + sprintOffset * 3])
#										rpc_id(
#										fightManager.opponent, "remote_card_move", 
#										curSlot + sprintOffset * 2,
#										curSlot + sprintOffset * 3,
#										false
#										)
										pushed = true
							
							if pushed:
								# A push has happened, recalculate stats
								for fCard in all_friendly_cards():
									fCard.calculate_buffs()
								for eCard in all_enemy_cards():
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
					# Spawn a card if thats the one
					if movSigil == "Squirrel Shedder":
						summon_card(CardInfo.from_name("Squirrel"), curSlot, friendly)
#						rpc_id(fightManager.opponent, "remote_card_summon", CardInfo.from_name("Squirrel"), curSlot)
					if movSigil == "Skeleton Crew":
						summon_card(CardInfo.from_name("Skeleton"), curSlot, friendly)
#						rpc_id(fightManager.opponent, "remote_card_summon", CardInfo.from_name("Skeleton"), curSlot)
					if card.card_data.name == "Long Elk":
						summon_card(CardInfo.from_name("Vertebrae"), curSlot, friendly)
#						rpc_id(fightManager.opponent, "remote_card_summon", CardInfo.from_name("Vertebrae"), curSlot)
						
				card.move_to_parent(affectedSlots[curSlot + sprintOffset])
#				rpc_id(
#					fightManager.opponent, "remote_card_move", 
#					curSlot,
#					curSlot + sprintOffset,
#					sprintSigil.flip_h != ogFlipped
#					)
				
				# A push has happened, recalculate stats
				for fCard in all_friendly_cards():
					fCard.calculate_buffs()
				for eCard in all_enemy_cards():
					eCard.calculate_buffs()
				
				# Wait for move to finish
				yield (cardTween, "tween_completed")
	
	# Other end-of-turn sigils
	for card in all_friendly_cards() if friendly else all_enemy_cards():
		if "Perish" in card.get_node("AnimationPlayer").current_animation:
			continue
		
		if card.has_sigil("Bone Digger"):
			fightManager.add_bones(1) if friendly else fightManager.add_opponent_bones(1)
#			fightManager.rpc_id(fightManager.opponent, "add_remote_bones", 1)
#			rpc_id(fightManager.opponent, "remote_card_anim", card.get_parent().get_position_in_parent(), "ProcGeneric")
			card.get_node("AnimationPlayer").play("ProcGeneric")
			yield(card.get_node("AnimationPlayer"), "animation_finished")
		
		# Diving
		if card.has_sigil("Waterborne") or card.has_sigil("Tentacle"):
#			rpc_id(fightManager.opponent, "remote_card_anim", card.get_parent().get_position_in_parent(), "Dive")
			card.get_node("AnimationPlayer").play("Dive")
			yield(card.get_node("AnimationPlayer"), "animation_finished")
	
		# Kill side deck cards if moon
		if fightManager.get_node("MoonFight/BothMoons/EnemyMoon").visible:
			for sn in ["Squirrel", "Skeleton", "Geck", "Vessel", "Ruby", "Sapphire", "Emerald", "Cairn"]:
				if sn in card.card_data.name:
					card.get_node("AnimationPlayer").play("Perish")
#					rpc_id(fightManager.opponent, "remote_card_anim", card.get_parent().get_position_in_parent(), "Perish")
					yield(card.get_node("AnimationPlayer"), "animation_finished")
				
			
	
	# Spawn conduit
	if get_friendly_cards_sigil("Spawn Conduit") and friendly:
		print("Spawn Conduit FRIENDLY")
		print(friendly)
		for sIdx in range(4):
			if is_slot_empty(playerSlots[sIdx]) and "Spawn Conduit" in get_conduitfx_friendly(sIdx):
#				rpc_id(fightManager.opponent, "remote_card_summon", CardInfo.from_name("L33pB0t"), sIdx)
				summon_card(CardInfo.from_name("L33pB0t"), sIdx, true)
	


	yield(get_tree().create_timer(0.01), "timeout")
	emit_signal("resolve_sigils")
	
	

# Combat
signal complete_combat()

func initiate_combat(friendly: bool):
	
	var attackingCards = all_friendly_cards() if friendly else all_enemy_cards()
	var attackingMoon = fightManager.get_node("MoonFight/BothMoons/FriendlyMoon") if friendly else fightManager.get_node("MoonFight/BothMoons/EnemyMoon")
	var defendingMoon = fightManager.get_node("MoonFight/BothMoons/EnemyMoon") if friendly else fightManager.get_node("MoonFight/BothMoons/FriendlyMoon")
	
	var attackingSlots = playerSlots if friendly else enemySlots
	var defendingSlots = playerSlots if not friendly else enemySlots
	
	if attackingMoon.visible:
		# Moon fight logic
		var moonAnim = fightManager.get_node("MoonFight/AnimationPlayer")
		
		# Attack face by default
		attackingMoon.target = -1
		
		if defendingMoon.visible:
			
			attackingMoon.target = 4
			moonAnim.play("friendlyMoonSlap" if friendly else "enemyMoonSlap")
			print("Moon attacking another moon!")
#			fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").rpc_id(fightManager.opponent, "remote_attack", 4)
			
			yield(get_tree().create_timer(0.2), "timeout")
#			rpc("handle_enemy_attack", 0, 0)
			
			yield(moonAnim, "animation_finished")
		
		else:
			for slot in range(4):
				attackingMoon.target = slot
				moonAnim.play("friendlyMoonSlap" if friendly else "enemyMoonSlap")
#				fightManager.get_node("MoonFight/BothMoons/EnemyMoon").rpc_id(fightManager.opponent, "remote_attack", moon.target)

				print("Moon attacking slot: %s" % attackingMoon.target)

				yield(moonAnim, "animation_finished")
			
		yield(get_tree().create_timer(0.01), "timeout")
		emit_signal("complete_combat")
		
		return
	
	for pCard in attackingCards:
		
		# TODO: FIX THIS
		if not pCard:
			continue

		if not is_instance_valid(pCard):
			continue
			
		if pCard.is_queued_for_deletion():
			continue

		var cardAnim = pCard.get_node("AnimationPlayer")
		var slot_index = pCard.slot_idx()
		
		if pCard.attack > 0 and not "Perish" in cardAnim.current_animation:
			
			if pCard.has_sigil("Trifurcated Strike") or pCard.has_sigil("Bifurcated Strike"):
				# Lower slot to right for attack anim (JANK AF)
				if slot_index < 3:
					attackingSlots[slot_index + 1].show_behind_parent = true
				
				# Tri strike attack
				for s_offset in range(-1, 2):
					yield(get_tree().create_timer(0.01), "timeout")
					
					# Break if attacker died from sharp quills
					if is_slot_empty(attackingSlots[slot_index]):
						break

					# Skip middle if bi-strike
					if s_offset == 0 and pCard.has_sigil("Bifurcated Strike"):
						continue

					# Prevent attacking out of bounds
					var atk_slot = slot_index + s_offset
					if atk_slot < 0 or atk_slot > 3:
						continue
					
					# Don't attack repulsive cards!
					if not is_slot_empty(defendingSlots[slot_index + s_offset]) and defendingSlots[slot_index + s_offset].get_child(0).has_sigil("Repulsive"):
						continue
					
					# Visually represent the card's attack offset (hacky)
					pCard.rect_position.x = s_offset * 50
#					rpc_id(fightManager.opponent, "set_card_offset", slot_index, s_offset * 50)
					
					pCard.strike_offset = s_offset
					cardAnim.play("Attack" if friendly else "AttackRemote")
#					rpc_id(fightManager.opponent, "remote_card_anim", slot_index, "AttackRemote")
					yield(cardAnim, "animation_finished")
				
				# Reset attack effect
				if slot_index < 3:
					attackingSlots[slot_index + 1].show_behind_parent = false
				
				if not is_slot_empty(attackingSlots[slot_index]):
					pCard.rect_position.x = 0
#					rpc_id(fightManager.opponent, "set_card_offset", slot_index, 0)
					
			else:

				# Wierd double strike condition
				for _i in range(2 if pCard.has_sigil("Double Strike") else 1):

					# Don't attack repulsive cards!
					if not is_slot_empty(defendingSlots[slot_index]) and defendingSlots[slot_index].get_child(0).has_sigil("Repulsive"):
						if not pCard.has_sigil("Airborne") or defendingSlots[slot_index].get_child(0).has_sigil("Mighty Leap"):
							continue
					
					cardAnim.play("Attack" if friendly else "AttackRemote")
#					rpc_id(fightManager.opponent, "remote_card_anim", slot_index, "AttackRemote")
					yield(cardAnim, "animation_finished")
		
					# Did the card get boned?
					if is_slot_empty(attackingSlots[slot_index]):
						continue
					
					# Any form of attack went through
					# Brittle: Die after attacking
					if pCard.has_sigil("Brittle"):
						cardAnim.play("Perish")
#						rpc_id(fightManager.opponent, "remote_card_anim", slot_index, "Perish")

	yield(get_tree().create_timer(0.01), "timeout")
	emit_signal("complete_combat")


# Do the attack damage
func handle_attack(from_slot, to_slot):
	
	print("Handling attack")
	
	var pCard = playerSlots[from_slot].get_child(0)

	# Special moon logic
	if fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").visible:
		# This means you're hitting something with the moon
		
		var moon = fightManager.get_node("MoonFight/BothMoons/FriendlyMoon")
		
		if moon.target == 4:
			fightManager.get_node("MoonFight/BothMoons/EnemyMoon").take_damage(moon.attack)
			return
		elif moon.target >= 0:
#			enemySlots[moon.target].get_child(0).take_damage(null, moon.attack)
			to_slot = moon.target
			pCard = moon
		else:
			fightManager.inflict_damage(moon.attack)
			return
		
	
	if fightManager.get_node("MoonFight/BothMoons/EnemyMoon").visible:
		# This means you're attacking the moon
		
		fightManager.get_node("MoonFight/BothMoons/EnemyMoon").take_damage(
			pCard.attack
		)
		
		print("ATTACK RPC ANTIMOON: ", to_slot)
#		rpc_id(fightManager.opponent, "handle_enemy_attack", from_slot, to_slot)
		
		return
	
	var direct_attack = false
	
	var eCard = null
	
	if is_slot_empty(enemySlots[to_slot]):
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
		
		if pCard.has_sigil("Side Hustle"):
			for _i in range(pCard.attack):
				if fightManager.side_deck.size() == 0:
					break
					
				fightManager.draw_card(fightManager.side_deck.pop_front(), fightManager.get_node("DrawPiles/YourDecks/SideDeck"))
		
				# Some interaction here if your deck has less than 3 cards. Don't punish I guess?
				if fightManager.side_deck.size() == 0:
					get_node("../DrawPiles/YourDecks/SideDeck").visible = false
					break
	else:
		eCard.take_damage(pCard)

		# On kill
		if eCard.health <= 0:
			if pCard.has_sigil("Blood Lust"):
				pCard.card_data.attack += 1
				pCard.draw_stats()
	
	print("ATTACK RPC: ", to_slot)
#	rpc_id(fightManager.opponent, "handle_enemy_attack", from_slot, to_slot)

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
func summon_card(cDat, slot_idx, friendly: bool):
	var nCard = fightManager.cardPrefab.instance()
	nCard.from_data(cDat)
	nCard.in_hand = false
	
	(playerSlots[slot_idx] if friendly else enemySlots[slot_idx]).add_child(nCard)
	
	fightManager.card_summoned(nCard)

	nCard.create_sigils(friendly)
	fightManager.connect("sigil_event", nCard, "handle_sigil_event")

# Remote
remote func set_sac_olay_vis(slot, vis):
	#Replay
	fightManager.replay.record_action({"type": "opponent_sac_olay", "slot": slot, "visible": vis})

	enemySlots[slot].get_child(0).get_node("CardBody/SacOlay").visible = vis

remote func remote_card_anim(slot, anim_name):

	# Replay
	fightManager.replay.record_action({"type": "opponent_card_anim", "slot": slot, "anim": anim_name})

	if is_slot_empty(enemySlots[slot]):
		return
	
	enemySlots[slot].get_child(0).get_node("AnimationPlayer").stop()
	enemySlots[slot].get_child(0).get_node("AnimationPlayer").play(anim_name)

func remote_card_summon(cDat, slot_idx):
	var nCard = fightManager.cardPrefab.instance()
	nCard.from_data(cDat)
	nCard.in_hand = false
	enemySlots[slot_idx].add_child(nCard)

	# Guardian (potentially client-side this)
	# if is_slot_empty(playerSlots[slot_idx]):
		# var guardians = get_friendly_cards_sigil("Guardian")
		# if guardians:
#			rpc_id(fightManager.opponent, "remote_card_move", guardians[0].get_parent().get_position_in_parent(), slot_idx, false)
			# guardians[0].move_to_parent(playerSlots[slot_idx])
	

remote func remote_activate_sigil(card_slot, arg = 0):

	# Replay
	fightManager.replay.record_action({"type": "opponent_activated_sigil", "slot": card_slot})

	var eCard = enemySlots[card_slot].get_child(0)
	var sName = eCard.card_data["sigils"][0]
	
	if sName == "True Scholar":
		eCard.get_node("AnimationPlayer").play("Perish")
		return
	
	if sName == "Energy Gun":

		if fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").visible:
			fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").take_damage(1)
			return
		
		var pCard = playerSlots[card_slot].get_child(0)
		fightManager.set_opponent_energy(fightManager.opponent_energy - 1)
		
		pCard.take_damage(get_enemy_card(card_slot), 1)

	if sName == "Power Dice":
		fightManager.set_opponent_energy(fightManager.opponent_energy - 2)
		
		var diff = eCard.attack - eCard.card_data["attack"]
		
		eCard.card_data["attack"] = arg
		
		eCard.attack = arg + diff

		eCard.draw_stats()
	
	if sName == "Enlarge":
		fightManager.add_opponent_bones(-2)
		eCard.health += 1

		eCard.card_data["attack"] += 1 # save attack to avoid bug
		eCard.attack += 1

		eCard.draw_stats()
	
	if sName == "Stimulate":
		fightManager.set_opponent_energy(fightManager.opponent_energy - 4)
		eCard.health += 1

		eCard.card_data["attack"] += 1 # save attack to avoid bug
		eCard.attack += 1

		eCard.draw_stats()
	
	if sName == "Bonehorn":
		fightManager.set_opponent_energy(fightManager.opponent_energy - 1)
		fightManager.add_opponent_bones(1)
	
	if sName == "Disentomb":
		fightManager.add_opponent_bones(-1)
	
#	Only animate if not dying
	if not "Perish" in eCard.get_node("AnimationPlayer").current_animation:
		eCard.get_node("AnimationPlayer").play("ProcGeneric")


remote func remote_card_move(from_slot, to_slot, flip_sigil):

	# Replay
	fightManager.replay.record_action({"type": "opponent_card_moved", "from_slot": from_slot, "to_slot": to_slot})

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
		
	# A push has happened, recalculate stats
	for fCard in all_friendly_cards():
		fCard.calculate_buffs()
	for eCard2 in all_enemy_cards():
		eCard2.calculate_buffs()

remote func remote_card_stats(card_slot, new_attack, new_health):
	var card = get_enemy_card(card_slot)
	card.attack = new_attack if new_attack != null else card.attack
	card.health = new_health if new_health != null else card.health
	card.draw_stats()

remote func remote_card_data(card_slot, new_data):
	var card = get_enemy_card(card_slot)
	card.from_data(new_data)

	# Calculate buffs
	for fCard in all_friendly_cards():
		fCard.calculate_buffs()
	for eCard in all_enemy_cards():
		eCard.calculate_buffs()
	
	# Hide tentacle atk symbol
	card.get_node("CardBody/AtkIcon").visible = false
	card.get_node("CardBody/HBoxContainer/AtkScore").visible = true

func handle_enemy_attack(from_slot, to_slot):

	fightManager.replay.record_action({"type": "enemy_attack", "from_slot": from_slot, "to_slot": to_slot})

	var eCard = get_enemy_card(from_slot)
	
	# Special moon logic
	if fightManager.get_node("MoonFight/BothMoons/EnemyMoon").visible:
		# This means they're hitting something with the moon
		
		var moon = fightManager.get_node("MoonFight/BothMoons/EnemyMoon")
		
		if fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").visible:
			fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").take_damage(moon.attack)
			return
		elif moon.target >= 0:
#			playerSlots[moon.target].get_child(0).take_damage(null, moon.attack)
			to_slot = moon.target
			eCard = moon
		else:
			fightManager.inflict_damage(-moon.attack)
			return
	
	if fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").visible:
		# This means they're attacking your moon
		
		fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").take_damage(
			enemySlots[from_slot].get_child(0).attack
		)
		return
	
	var direct_attack = false
	
	var pCard = null
	
	if is_slot_empty(playerSlots[to_slot]):
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
		pCard.take_damage(eCard)

		# On kill
		if pCard.health <= 0:
			if eCard.has_sigil("Blood Lust"):
				eCard.card_data.attack += 1
				eCard.draw_stats()
					
# Something for tri strike effect
remote func set_card_offset(card_slot, offset):
	if is_slot_empty(enemySlots[card_slot]):
		return
	
	if card_slot < 3:
		if offset > 0:
			enemySlots[card_slot + 1].show_behind_parent = true
		else:
			enemySlots[card_slot + 1].show_behind_parent = false
	
	enemySlots[card_slot].get_child(0).rect_position.x = offset

# Conduit madness
func get_conduitfx(card):
	
	var slot_idx = card.slot_idx()
	var slots = card.get_parent().get_parent().get_children()
	
	var conduitfx = []

	var lconduit = false
	var rconduit = false

	# Check slots left of slot_idx
	for sIdx in range(slot_idx - 1, -1, -1):
		if not is_slot_empty(slots[sIdx]):
			if "conduit" in slots[sIdx].get_child(0).card_data:
				lconduit = slots[sIdx].get_child(0)
				if "sigils" in lconduit.card_data:
					conduitfx.append_array(lconduit.card_data["sigils"])


	# Check slots right of slot_idx
	for sIdx in range(slot_idx + 1, 4):
		if not is_slot_empty(slots[sIdx]):
			if "conduit" in slots[sIdx].get_child(0).card_data:
				rconduit = slots[sIdx].get_child(0)
				if "sigils" in rconduit.card_data:
					conduitfx.append_array(rconduit.card_data["sigils"])
	
	if not (lconduit and rconduit):
		return []
	
	if conduitfx == []:
		conduitfx = ["Basic"]
	
	print("Card at slot ", slot_idx, " has conduit fx: ", conduitfx)
	
	return conduitfx

func get_conduitfx_friendly(slot_idx):

	var slots = playerSlots
	
	var conduitfx = []

	var lconduit = false
	var rconduit = false

	# Check slots left of slot_idx
	for sIdx in range(slot_idx - 1, -1, -1):
		if not is_slot_empty(slots[sIdx]):
			if "conduit" in slots[sIdx].get_child(0).card_data:
				lconduit = slots[sIdx].get_child(0)
				if "sigils" in lconduit.card_data:
					conduitfx.append_array(lconduit.card_data["sigils"])


	# Check slots right of slot_idx
	for sIdx in range(slot_idx + 1, 4):
		if not is_slot_empty(slots[sIdx]):
			if "conduit" in slots[sIdx].get_child(0).card_data:
				rconduit = slots[sIdx].get_child(0)
				if "sigils" in rconduit.card_data:
					conduitfx.append_array(rconduit.card_data["sigils"])
	
	if not (lconduit and rconduit):
		return []
	
	if conduitfx == []:
		conduitfx = ["Basic"]
	
	print("Card at slot ", slot_idx, " has conduit fx: ", conduitfx)
	
	return conduitfx

func get_conduitfx_enemy(slot_idx):

	var slots = enemySlots
	
	var conduitfx = []

	var lconduit = false
	var rconduit = false

	# Check slots left of slot_idx
	for sIdx in range(slot_idx - 1, -1, -1):
		if not is_slot_empty(slots[sIdx]):
			if "conduit" in slots[sIdx].get_child(0).card_data:
				lconduit = slots[sIdx].get_child(0)
				if "sigils" in lconduit.card_data:
					conduitfx.append_array(lconduit.card_data["sigils"])


	# Check slots right of slot_idx
	for sIdx in range(slot_idx + 1, 4):
		if not is_slot_empty(slots[sIdx]):
			if "conduit" in slots[sIdx].get_child(0).card_data:
				rconduit = slots[sIdx].get_child(0)
				if "sigils" in rconduit.card_data:
					conduitfx.append_array(rconduit.card_data["sigils"])
	
	if not (lconduit and rconduit):
		return []
	
	if conduitfx == []:
		conduitfx = ["Basic"]
	
	print("Card at slot ", slot_idx, " has conduit fx: ", conduitfx)
	
	return conduitfx

# New Helper functions
func get_friendly_card(slot_idx):
	
	if slot_idx > 3 or slot_idx < 0:
		return false
	
	for card in playerSlots[slot_idx].get_children():
		if not "Perish" in card.get_node("AnimationPlayer").current_animation:
			return card
	return false

func get_enemy_card(slot_idx):
	
	if slot_idx > 3 or slot_idx < 0:
		return false
	
	for card in enemySlots[slot_idx].get_children():
		if not "Perish" in card.get_node("AnimationPlayer").current_animation:
			return card
	return false

func all_friendly_cards():
	var cards = []

	for slot in playerSlots:
		if not is_slot_empty(slot):
			cards.append(slot.get_child(0))
	
	return cards

func all_enemy_cards():
	var cards = []

	for slot in enemySlots:
		if not is_slot_empty(slot):
			cards.append(slot.get_child(0))
	
	return cards

func is_slot_empty(slot):
	if slot.get_child_count() and slot.get_child(0).is_alive():
		return false

	return true
