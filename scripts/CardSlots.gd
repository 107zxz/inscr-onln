extends Control

var player_slots
var player_slots_back
var enemy_slots
var enemy_slots_back
var friendly_conduit_data = [-1, -1]
var enemy_conduit_data = [-1, -1]
onready var fightManager = get_node("/root/Main/CardFight")
onready var handManager = fightManager.get_node("HandsContainer/Hands")
onready var nLanes = CardInfo.all_data.n_lanes

# Cards selected for sacrifice
var sac_victims = []

func _ready():
	var slotGroups = [$PlayerSlots, $PlayerSlotsBack, $EnemySlots, $EnemySlotsBack]
	var newSlot
	var isBack = false
	var template

	for group in slotGroups:
		for slot in group.get_children():
			slot.queue_free()
		template = $SlotTemplateBack if isBack else $SlotTemplate
		isBack = not isBack
		for i in range(nLanes):
			newSlot = template.duplicate()
			newSlot.name = "Slot" + str(i)
			newSlot.visible = group.visible
			group.add_child(newSlot)

	player_slots = $PlayerSlots.get_children()
	player_slots_back = $PlayerSlotsBack.get_children()
	enemy_slots = $EnemySlots.get_children()
	enemy_slots_back = $EnemySlotsBack.get_children()

# Board interactions
func clear_slots():
#	for card in all_friendly_cards():
#		card.queue_free()
#	for card in all_enemy_cards():
#		card.queue_free()

	# Abracadabra bitch
	for slot in (player_slots + enemy_slots):
		for child in slot.get_children():
			child.queue_free()

# Sacrifice
func get_available_blood() -> int:
	var blood = 0

	var sac_targets = all_friendly_cards_backrow() if CardInfo.all_data.enable_backrow else all_friendly_cards()

	for card in sac_targets:
#		if card.has_sigil("Noble Sacrifice"):
#			blood += 1
#		if card.has_sigil("Worthy Sacrifice"):
#			blood += 2
		# Don't allow saccing mox cards
		if "nosac" in card.card_data:
			continue
		var card_blood = card.calc_blood()
		if(card_blood > 0):
			blood += card_blood

	return blood

func get_available_slots() -> int:
	var free_slots = nLanes

	for _card in all_friendly_cards():
		free_slots -= 1

	return free_slots

func get_hammerable_cards():
	var hammerable = 0

	for card in all_friendly_cards():
		if not "nohammer" in card.card_data:
			hammerable += 1

	return hammerable

func is_cat_bricked() -> bool:
	
	# We aren't bricked if a slot is free
	if get_available_slots():
		return false

	# We aren't bricked if a card is saccable and has NONE of these sigils
	for card in all_friendly_cards():
		if "nosac" in card.card_data:
			continue
		
		# If the card has no sigils we good
		if not "sigils" in card.card_data:
			return false
		
		for sigil in card.card_data.sigils:
			if sigil in ["Many Lives", "Frozen Away", "Ruby Heart"]:
				continue
		
	return true

func clear_sacrifices():
	for victim in sac_victims:
		victim.get_node("CardBody/SacOlay").visible = false
		rpc_id(fightManager.opponent, "set_sac_olay_vis", victim.get_parent().get_position_in_parent(), false)

	sac_victims.clear()

func attempt_sacrifice():

	var sac_value = 0

	for victim in sac_victims:
		sac_value += victim.calc_blood()
#		if victim.has_sigil("Worthy Sacrifice"):
#			sacValue += 2
#		if victim.has_sigil("Noble Sacrifice"):
#			sacValue += 1

	if sac_value >= handManager.raisedCard.card_data["blood_cost"]:
		
		# Catbrick check (for real this time)
		if not get_available_slots():
			print("Checking for catbrick...")
			var bricked = true
			for v in sac_victims:
				if v.has_sigil("Many Lives") or v.has_sigil("Frozen Away") or v.has_sigil("Ruby Heart"):
					continue
				bricked = false
			if bricked:
				print("Catbricked!!!")
				clear_sacrifices()
				return
		
		# Kill sacrifical victims
		for victim in sac_victims:
			if victim.has_sigil("Many Lives"):
				victim.get_node("AnimationPlayer").play("CatSac")
#				rpc_id(fightManager.opponent, "remote_card_anim", victim.slot_idx(), "CatSac")
				fightManager.send_move({
					"type": "card_anim",
					"index": victim.slot_idx(),
					"anim": "CatSac"
				})

				victim.sacrificeCount += 1

				# Undeadd cat
				if victim.card_data["name"] == "Cat" and victim.sacrificeCount == 9:
					victim.from_data(CardInfo.from_name("Undead Cat"))
#					rpc_id(fightManager.opponent, "remote_card_data", victim.slot_idx(), CardInfo.from_name("Undead Cat"))

					fightManager.send_move({
						"type": "change_card",
						"index": victim.slot_idx(),
						"data": CardInfo.from_name("Undead Cat")
					})

			else:
				victim.get_node("AnimationPlayer").play("Perish")
#				rpc_id(fightManager.opponent, "remote_card_anim", victim.slot_idx(), "Perish")
				fightManager.send_move({
					"type": "card_anim",
					"index": victim.slot_idx(),
					"anim": "Perish"
				})


		sac_victims.clear()

		# Force player to summon the new card
		if get_available_slots():
			fightManager.state = fightManager.GameStates.FORCEPLAY

# Break flow to handle sigils
signal resolve_sigils()

func pre_turn_sigils(friendly: bool):

	# Shift cards first
	if CardInfo.all_data.enable_backrow:
		shift_cards_forward(false)

	var cards_to_move = all_friendly_cards() if friendly else all_enemy_cards()

	for card in cards_to_move:
		var card_anim = card.get_node("AnimationPlayer")

		if card_anim.is_playing():
			continue

		if card.get_parent().get_parent().name == "PlayerSlots" and CardInfo.all_data.opt_actives and "active" in card.card_data:
			var cd = card.get_node("CardBody/Active")
			cd.disabled = false
			cd.mouse_filter = MOUSE_FILTER_STOP
		
		for sig in card.grouped_sigils[SigilEffect.SigilTriggers.START_OF_TURN]:
			sig.start_of_turn(card_anim)
		
#		# Evolution
#		if card.has_sigil("Fledgling") or card.has_sigil("Fledgling 2") or card.has_sigil("Transformer"):
#			card_anim.play("Evolve")
#			yield (card_anim, "animation_finished")
#
#		# Dive
#		if card.get_node("CardBody/DiveOlay").visible:
#			card_anim.play("UnDive")
#
#			if card.has_sigil("Tentacle"):
#				var nTent = CardInfo.from_name(["Bell Tentacle", "Hand Tentacle", "Mirror Tentacle"][ (["Great Kraken", "Bell Tentacle", "Hand Tentacle", "Mirror Tentacle"].find(card.card_data.name)) % 3 ])
#
#				var hp = card.health
#				card.from_data(nTent)
#				card.health = hp
#
#				# Calculate
#				for fCard in all_friendly_cards():
#					fCard.calculate_buffs()
#				for eCard in all_enemy_cards():
#					eCard.calculate_buffs()
#
#				# Hide tentacle atk symbol
#				card.get_node("CardBody/AtkIcon").visible = false
#				card.get_node("CardBody/AtkScore").visible = true

	# Enemy spawn conduit
#	if get_enemy_cards_sigil("Spawn Conduit") and friendly:
#		print("Spawn Conduit ENEMY")
#		print(friendly)
#		for sIdx in range(4):
#			if is_slot_empty(enemy_slots[sIdx]) and "Spawn Conduit" in get_conduitfx_enemy(sIdx):
#				summon_card(CardInfo.from_name("L33pB0t"), sIdx, false)

	yield(get_tree().create_timer(0.01), "timeout")
	emit_signal("resolve_sigils")

func post_turn_sigils(friendly: bool):
	var cards_to_move = all_friendly_cards() if friendly else all_enemy_cards()

	var affected_slots = player_slots if friendly else enemy_slots

	# Sprinting
#	for card in cards_to_move:
#		var card_anim = card.get_node("AnimationPlayer")
#		var cardTween = card.get_node("Tween")
#
#		# Spront
#		for movSigil in ["Sprinter", "Squirrel Shedder", "Skeleton Crew", "Skeleton Crew (Yarr)", "Hefty"]:
#			if card.has_sigil(movSigil) and not "Perish" in card_anim.current_animation:
#
#				var sprintSigil = card.get_node("CardBody/Sigils/Row1").get_child(
#					card.card_data["sigils"].find(movSigil)
#				)
#
#				var curSlot = card.get_parent().get_position_in_parent()
#
#				var sprintOffset = -1 if sprintSigil.flip_h else 1
#				var moveFailed = false
#				var cantMove = false
##				var ogFlipped = sprintSigil.flip_h
#
#				for _i in range(2):
#					# Edges of screen
#					if curSlot + sprintOffset > 3:
#						if moveFailed:
#							cantMove = true
#							break
#						sprintSigil.flip_h = true
#						moveFailed = true
#					elif curSlot + sprintOffset < 0:
#						if moveFailed:
#							cantMove = true
#							break
#						sprintSigil.flip_h = false
#						moveFailed = true
#
#					# Occupied slots
#					elif not is_slot_empty(affectedSlots[curSlot + sprintOffset]): # and not affectedSlots[curSlot + sprintOffset].get_child(0).get_node("AnimationPlayer").is_playing():
#
#						if movSigil == "Hefty":
#
#							var pushed = false
#
#							if curSlot + sprintOffset * 2 <= 3 and curSlot + sprintOffset * 2 >= 0:
#								if is_slot_empty(affectedSlots[curSlot + sprintOffset * 2]): # or affectedSlots[curSlot + sprintOffset * 2].get_child(0).get_node("AnimationPlayer").is_playing():
#									affectedSlots[curSlot + sprintOffset].get_child(0).move_to_parent(affectedSlots[curSlot + sprintOffset * 2])
#									pushed = true
#
#								elif curSlot + sprintOffset * 3 <= 3 and curSlot + sprintOffset * 3 >= 0:
#									if is_slot_empty(affectedSlots[curSlot + sprintOffset * 3]): # or affectedSlots[curSlot + sprintOffset * 3].get_child(0).get_node("AnimationPlayer").is_playing():
#										affectedSlots[curSlot + sprintOffset].get_child(0).move_to_parent(affectedSlots[curSlot + sprintOffset * 2])
#										affectedSlots[curSlot + sprintOffset * 2].get_child(0).move_to_parent(affectedSlots[curSlot + sprintOffset * 3])
#										pushed = true
#
#							if pushed:
#								# A push has happened, recalculate stats
#								for fCard in all_friendly_cards():
#									fCard.calculate_buffs()
#								for eCard in all_enemy_cards():
#									eCard.calculate_buffs()
#							else:
#								if moveFailed:
#									cantMove = true
#									break
#								sprintSigil.flip_h = not sprintSigil.flip_h
#								moveFailed = true
#						else:
#							if moveFailed:
#								cantMove = true
#								break
#							sprintSigil.flip_h = not sprintSigil.flip_h
#							moveFailed = true
#
#					sprintOffset = -1 if sprintSigil.flip_h else 1
#
#				if cantMove:
#					sprintOffset = 0
#				else:
#					# Spawn a card if thats the one
#					if movSigil == "Squirrel Shedder":
#						summon_card(CardInfo.from_name("Squirrel"), curSlot, friendly)
#					if movSigil == "Skeleton Crew":
#						summon_card(CardInfo.from_name("Skeleton"), curSlot, friendly)
#					if movSigil == "Skeleton Crew (Yarr)":
#						summon_card(CardInfo.from_name("Skeleton Crew"), curSlot, friendly)
#
#					if "sheds" in card.card_data:
#						summon_card(CardInfo.from_name(card.card_data.sheds), curSlot, friendly)
#
#				card.move_to_parent(affectedSlots[curSlot + sprintOffset])
#
#
#				# A push has happened, recalculate stats
#				for fCard in all_friendly_cards():
#					fCard.calculate_buffs()
#				for eCard in all_enemy_cards():
#					eCard.calculate_buffs()
#
#				# Wait for move to finish
#				yield (cardTween, "tween_completed")

	# Other end-of-turn sigils
	for card in all_friendly_cards() if friendly else all_enemy_cards():
		if "Perish" in card.get_node("AnimationPlayer").current_animation:
			continue
		
		var card_anim = card.get_node("AnimationPlayer")
		
		for sig in card.grouped_sigils[SigilEffect.SigilTriggers.END_OF_TURN]:
			sig.end_of_turn(card_anim)

#		if card.has_sigil("Bone Digger"):
#			fightManager.add_bones(1) if friendly else fightManager.add_opponent_bones(1)
#			card.get_node("AnimationPlayer").play("ProcGeneric")
#			yield(card.get_node("AnimationPlayer"), "animation_finished")
#
#		# Diving
#		if card.has_sigil("Waterborne") or card.has_sigil("Tentacle"):
#			card.get_node("AnimationPlayer").play("Dive")
#			yield(card.get_node("AnimationPlayer"), "animation_finished")

		# Kill side deck cards if moon
		if fightManager.get_node("MoonFight/BothMoons/EnemyMoon").visible:
			for sn in ["Squirrel", "Skeleton", "Geck", "Vessel", "Ruby", "Sapphire", "Emerald", "Cairn"]:
				if sn in card.card_data.name:
					card.get_node("AnimationPlayer").play("Perish")
					yield(card.get_node("AnimationPlayer"), "animation_finished")



	# Spawn conduit
#	if get_friendly_cards_sigil("Spawn Conduit") and friendly:
#		print("Spawn Conduit FRIENDLY")
#		print(friendly)
#		for sIdx in range(4):
#			if is_slot_empty(player_slots[sIdx]) and "Spawn Conduit" in get_conduitfx_friendly(sIdx):
##				rpc_id(fightManager.opponent, "remote_card_summon", CardInfo.from_name("L33pB0t"), sIdx)
#				summon_card(CardInfo.from_name("L33pB0t"), sIdx, true)

	yield(get_tree().create_timer(0.01), "timeout")
	emit_signal("resolve_sigils")

# Combat
signal complete_combat()

func initiate_combat(friendly: bool):

	var attacking_cards = all_friendly_cards() if friendly else all_enemy_cards()
	var attacking_moon = fightManager.get_node("MoonFight/BothMoons/FriendlyMoon") if friendly else fightManager.get_node("MoonFight/BothMoons/EnemyMoon")
	var defending_moon = fightManager.get_node("MoonFight/BothMoons/EnemyMoon") if friendly else fightManager.get_node("MoonFight/BothMoons/FriendlyMoon")

	var attacking_slots = player_slots if friendly else enemy_slots
	var defending_slots = player_slots if not friendly else enemy_slots

	if attacking_moon.visible:
		# Moon fight logic
		var moon_anim = fightManager.get_node("MoonFight/AnimationPlayer")

		# Attack face by default
		attacking_moon.target = -1

		if defending_moon.visible:

			attacking_moon.target = nLanes
			moon_anim.play("friendlyMoonSlap" if friendly else "enemyMoonSlap")
			print("Moon attacking another moon!")
#			fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").rpc_id(fightManager.opponent, "remote_attack", nLanes)

			yield(get_tree().create_timer(0.2), "timeout")
#			rpc("handle_enemy_attack", 0, 0)

			yield(moon_anim, "animation_finished")

		else:
			for slot in range(nLanes):
				attacking_moon.target = slot
				moon_anim.play("friendlyMoonSlap" if friendly else "enemyMoonSlap")
#				fightManager.get_node("MoonFight/BothMoons/EnemyMoon").rpc_id(fightManager.opponent, "remote_attack", moon.target)

				print("Moon attacking slot: %s" % attacking_moon.target)

				yield(moon_anim, "animation_finished")

		yield(get_tree().create_timer(0.01), "timeout")
		emit_signal("complete_combat")

		return

	for attacking_card in attacking_cards:

		# TODO: FIX THIS
		# fix what?
		if not attacking_card:
			continue

		if not is_instance_valid(attacking_card):
			continue

		if attacking_card.is_queued_for_deletion():
			continue

		var card_anim = attacking_card.get_node("AnimationPlayer")
		var slot_index = attacking_card.slot_idx()

		if attacking_card.attack <= 0 or "Perish" in card_anim.current_animation:
			continue
	
		# what enemy indexes need to be attacked and how many times?
		# strikes[nLanes] exists to 'null' invalid strike indexes (-1 and nLanes)
		var strikes = []
		strikes.resize(nLanes + 1)
		strikes.fill(0)
		
		# if pCard.has_sigil("Omni Strike"):
		#	
		#	for eCard in all_enemy_cards():
		#		strikes[eCard.slot_idx()] = 1
		#	if not 1 in strikes:
		#		strikes[slot_index] = 1

		# else:
			
		strikes[slot_index] += 1
		for sig in attacking_card.grouped_sigils[SigilEffect.SigilTriggers.MODIFY_ATTACK_TARGETING]:
			strikes = sig.modify_attack_targeting(slot_index, strikes)
		
			# strikes[slot_index] += 0 if pCard.has_sigil("Bifurcated Strike") else 1
			# strikes[slot_index] += 1 if pCard.has_sigil("Double Strike") else 0
			# strike to each side once per peripheral striking sigil
			# for _i in range((1 if pCard.has_sigil("Bifurcated Strike") else 0) + (1 if pCard.has_sigil("Trifurcated Strike") else 0)):
			#	strikes[slot_index - 1] += 1
			#	strikes[slot_index + 1] += 1

		
		# brittle check
		var has_attacked = false
		
		if attacking_card.has_sigil("Sniper"):
			
			# sniping time
			var target_index
			
			print("Sniper handler, friendly: ", friendly)
			var total_strikes = 0

			for strike in strikes:
				total_strikes += strike

			for _i in range(total_strikes):
				
				# opponent or attacking card might die mid-attacking
				if is_slot_empty(attacking_slots[slot_index]) or (fightManager.opponent_lives if friendly else fightManager.lives) == 0:
					break

				if friendly:
					fightManager.sniper = attacking_card
					fightManager.state = fightManager.GameStates.SNIPE
					fightManager.snipe_is_attack = true
					target_index = yield(fightManager, "snipe_complete")[3]
					fightManager.state = fightManager.GameStates.BATTLE

				elif fightManager.sniper_targets:
					print(fightManager.sniper_targets)
					target_index = fightManager.sniper_targets[0]
				
				pre_attack_logic(friendly, attacking_card, target_index)
				
				# don't attack repulsive cards!
#				if not is_slot_empty(defendingSlots[target_index]) and defendingSlots[target_index].get_child(0).has_sigil("Repulsive"):
#					if not pCard.has_sigil("Airborne") or defendingSlots[target_index].get_child(0).has_sigil("Mighty Leap"):
#						fightManager.sniper_targets.pop_front()
#						continue
				var defending_card = null
				if not is_slot_empty(defending_slots[target_index]):
					defending_card = defending_slots[target_index].get_child(0)

				if get_attack_targeting(friendly, attacking_card, defending_card) != SigilEffect.AttackTargeting.FAILURE:
					has_attacked = true
					attacking_card.strike_offset = target_index - slot_index
					card_anim.play("Attack" if friendly else "AttackRemote")
					attacking_card.play_sfx("attack")
					yield(card_anim, "animation_finished")
				else:
					yield(attacking_card.get_tree().create_timer(0.3), "timeout")
				fightManager.sniper_targets.pop_front()

		else:
	
			# die, irrelevant index
			strikes.pop_back()
			
			for i in range(nLanes):
				
				for _i in range(strikes[i]):

					# opponent or attacking creature might die mid-attackiing
					if is_slot_empty(attacking_slots[slot_index]) or (fightManager.opponent_lives if friendly else fightManager.lives) == 0:
						break
					
					# don't attack repulsive cards!
#					if not is_slot_empty(defendingSlots[i]) and defendingSlots[i].get_child(0).has_sigil("Repulsive"):
#						if not pCard.has_sigil("Airborne") or defendingSlots[i].get_child(0).has_sigil("Mighty Leap"):
#							continue
					pre_attack_logic(friendly, attacking_card, i)
					
					var eCard = null
					if not is_slot_empty(defending_slots[i]):
						eCard = defending_slots[i].get_child(0)

					if get_attack_targeting(friendly, attacking_card, eCard) != SigilEffect.AttackTargeting.FAILURE:
						has_attacked = true
						attacking_card.strike_offset = i - slot_index
						attacking_card.rect_position.x = attacking_card.strike_offset * 50
						card_anim.play("Attack" if friendly else "AttackRemote")
						attacking_card.play_sfx("attack")
						yield(card_anim, "animation_finished")
					else:
						yield(attacking_card.get_tree().create_timer(0.3), "timeout")
					
					if is_slot_empty(attacking_slots[slot_index]):
						continue
					
					attacking_card.rect_position.x = 0
		
		#if has_attacked and pCard.has_sigil("Brittle"):
		#	card_anim.play("Perish")
		for sig in attacking_card.grouped_sigils[SigilEffect.SigilTriggers.AFTER_ATTACKS]:
			sig.after_attacks(card_anim, has_attacked)

	yield(get_tree().create_timer(0.01), "timeout")

	if fightManager.state == fightManager.GameStates.SNIPE:
		fightManager.get_node("WaitingBlocker").hide()
		yield(fightManager, "snipe_complete")

	emit_signal("complete_combat")


func pre_attack_logic(friendly: bool, attacker, to_slot):
	if friendly:
		var attack_targeting = SigilEffect.AttackTargeting.SCALE if is_slot_empty(enemy_slots[to_slot]) else SigilEffect.AttackTargeting.CARD
		for enemy_card in all_enemy_cards():
			for sig in enemy_card.grouped_sigils[SigilEffect.SigilTriggers.PRE_ENEMY_ATTACK]:
				# I put the mole logic in here!
				sig.pre_enemy_attack(attacker, to_slot, attack_targeting)
	else:
		var attack_targeting = SigilEffect.AttackTargeting.SCALE if is_slot_empty(player_slots[to_slot]) else SigilEffect.AttackTargeting.CARD
		for player_card in all_friendly_cards():
			for sig in player_card.grouped_sigils[SigilEffect.SigilTriggers.PRE_ENEMY_ATTACK]:
				# I put the mole logic in here!
				sig.pre_enemy_attack(attacker, to_slot, attack_targeting)

func get_attack_targeting(friendly: bool, attacker, defender):
	
#	print("Getting Attack Targeting")
#	print("Friendly = %s" % friendly)
#	print("Attacker = %s" % attacker.card_data)
#	if defender:
#		print("Defender = %s" % defender.card_data)
#	else:
#		print("No Defender")
	
	var attack_targeting = SigilEffect.AttackTargeting.CARD if defender else SigilEffect.AttackTargeting.SCALE
	
	for sig in attacker.grouped_sigils[SigilEffect.SigilTriggers.ATTACKER_TARGET_SELECTING]:
		attack_targeting = sig.attacker_target_selecting(attack_targeting, defender)
	
	if defender:
		for sig in defender.grouped_sigils[SigilEffect.SigilTriggers.DEFENDER_TARGET_SELECTING]:
			attack_targeting = sig.defender_target_selecting(attack_targeting, attacker)
	
#	print(SigilEffect.AttackTargeting.keys()[attack_targeting])

	return attack_targeting

# Do the attack damage
func handle_attack(from_slot, to_slot):

	print("Handling attack")

	var attacking_card = player_slots[from_slot].get_child(0)

	# Special moon logic
	if fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").visible:
		# This means you're hitting something with the moon

		var moon = fightManager.get_node("MoonFight/BothMoons/FriendlyMoon")

		if moon.target == nLanes:
			fightManager.get_node("MoonFight/BothMoons/EnemyMoon").take_damage(moon.attack)
			return
		elif moon.target >= 0:
#			enemy_slots[moon.target].get_child(0).take_damage(null, moon.attack)
			to_slot = moon.target
			attacking_card = moon
		else:
			fightManager.inflict_damage(moon.attack)
			return


	if fightManager.get_node("MoonFight/BothMoons/EnemyMoon").visible:
		# This means you're attacking the moon

		fightManager.get_node("MoonFight/BothMoons/EnemyMoon").take_damage(
			attacking_card.attack
		)

		print("ATTACK RPC ANTIMOON: ", to_slot)
#		rpc_id(fightManager.opponent, "handle_enemy_attack", from_slot, to_slot)

		return

#	var attack_targeting = SigilEffect.AttackTargeting.SCALE if is_slot_empty(enemy_slots[to_slot]) else SigilEffect.AttackTargeting.CARD

	#var direct_attack = false

#	var eCard = null
#
##	Migrate mole logic, hopefully?
#
#
#	if not is_slot_empty(enemy_slots[to_slot]):
#		eCard = enemy_slots[to_slot].get_child(0)
#
#	var attack_targeting = SigilEffect.AttackTargeting.SCALE if is_slot_empty(enemy_slots[to_slot]) else SigilEffect.AttackTargeting.CARD
#
#	for sig in pCard.grouped_sigils[SigilEffect.SigilTriggers.ATTACKER_TARGET_SELECTING]:
#		attack_targeting = sig.attacker_target_selecting(attack_targeting, eCard)
#
#	if eCard:
#		for sig in eCard.grouped_sigils[SigilEffect.SigilTriggers.DEFENDER_TARGET_SELECTING]:
#			attack_targeting = sig.defender_target_selecting(attack_targeting, pCard)
	
#	if is_slot_empty(enemy_slots[to_slot]):
#		direct_attack = true
#
#		# Check for moles
#		# Mole man
#		if pCard.has_sigil("Airborne"):
#			for card in all_enemy_cards():
#				if card.has_sigil("Burrower") and card.has_sigil("Mighty Leap"):
#					direct_attack = false
#					card.move_to_parent(enemy_slots[to_slot])
#					eCard = card
#					break
#		else: # Regular mole
#			for card in all_enemy_cards():
#				if card.has_sigil("Burrower"):
#					direct_attack = false
#					card.move_to_parent(enemy_slots[to_slot])
#					eCard = card
#					break
#
#	else:
#		eCard = enemy_slots[to_slot].get_child(0)
#		if pCard.has_sigil("Airborne") and not eCard.has_sigil("Mighty Leap"):
#			direct_attack = true
#		if eCard.get_node("CardBody/DiveOlay").visible:
#			direct_attack = true
#
#
#
#	if direct_attack:
	
	var defendingCard = null

	if not is_slot_empty(enemy_slots[to_slot]):
		defendingCard = enemy_slots[to_slot].get_child(0)
	
	var attack_targeting = get_attack_targeting(true, attacking_card, defendingCard)

	# if, after everything, the attack targeting is SCALE: go face
	if attack_targeting == SigilEffect.AttackTargeting.SCALE:

		# Variable attack override

#		fightManager.inflict_damage(pCard.attack if not CardInfo.all_data.variable_attack_nerf or  else 1)
		
		var damage = 1 if "atkspecial" in attacking_card.card_data and CardInfo.all_data.variable_attack_nerf else attacking_card.attack

		fightManager.inflict_damage(damage)


		for sig in attacking_card.grouped_sigils[SigilEffect.SigilTriggers.ON_DAMAGE_SCALE]:
			sig.on_damage_scale(damage)
		# Looter
#		if pCard.has_sigil("Looter"):
#			for _i in range(pCard.attack):
#				if fightManager.deck.size() == 0:
#					break
#
#				fightManager.draw_card(fightManager.deck.pop_front())
#
#				# Some interaction here if your deck has less than 3 cards. Don't punish I guess?
#				if fightManager.deck.size() == 0:
#					get_node("../DrawPiles/YourDecks/Deck").visible = false
#					break
#
#		if pCard.has_sigil("Side Hustle"):
#			for _i in range(pCard.attack):
#				if fightManager.side_deck.size() == 0:
#					break
#
#				fightManager.draw_card(fightManager.side_deck.pop_front(), fightManager.get_node("DrawPiles/YourDecks/SideDeck"))
#
#				# Some interaction here if your deck has less than 3 cards. Don't punish I guess?
#				if fightManager.side_deck.size() == 0:
#					get_node("../DrawPiles/YourDecks/SideDeck").visible = false
#					break
#	else:
#		# Gross hard-coded exception
#		if not eCard.has_sigil("Repulsive"):
#			eCard.take_damage(pCard)

	#if, after everthing, the attack type is CARD: hit the card.
	elif attack_targeting == SigilEffect.AttackTargeting.CARD:
		defendingCard.take_damage(attacking_card)
	
	#if, after everthing, the attack type is FAULURE: do nothing, probably because you got damage-blocked by someone with Repulsive
	else:
		pass

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
	var new_card = fightManager.cardPrefab.instance()
	(player_slots[slot_idx] if friendly else enemy_slots[slot_idx]).add_child(new_card)
	new_card.from_data(cDat)
	new_card.in_hand = false


	fightManager.card_summoned(new_card)

	new_card.create_sigils(friendly)
	fightManager.connect("sigil_event", new_card, "handle_sigil_event")

# Remote
remote func set_sac_olay_vis(slot, vis):
	enemy_slots[slot].get_child(0).get_node("CardBody/SacOlay").visible = vis

func remote_card_anim(slot, anim_name):

	if is_slot_empty(enemy_slots[slot]):
		return

	enemy_slots[slot].get_child(0).get_node("AnimationPlayer").stop()
	enemy_slots[slot].get_child(0).get_node("AnimationPlayer").play(anim_name)
	fightManager.move_done()


func remote_card_summon(cDat, slot_idx):
	var new_card = fightManager.cardPrefab.instance()
	new_card.from_data(cDat)
	new_card.in_hand = false
	enemy_slots[slot_idx].add_child(new_card)

	# Guardian (potentially client-side this)
	# if is_slot_empty(player_slots[slot_idx]):
		# var guardians = get_friendly_cards_sigil("Guardian")
		# if guardians:
#			rpc_id(fightManager.opponent, "remote_card_move", guardians[0].get_parent().get_position_in_parent(), slot_idx, false)
			# guardians[0].move_to_parent(player_slots[slot_idx])


func remote_activate_sigil(card_slot, arg = 0):

	var enemy_card = enemy_slots[card_slot].get_child(0)
	var sig_name = enemy_card.card_data["sigils"][0]

	if sig_name == "True Scholar":
		enemy_card.get_node("AnimationPlayer").play("Perish")
		yield(enemy_card.get_node("AnimationPlayer"), "animation_finished")
		fightManager.move_done()
		return

	if sig_name == "Acupuncture":
		var player_card = get_friendly_card(arg)
		fightManager.add_opponent_bones(-3)

		# Add the new sigil to the card
		var new_sigs = []
		
		if "sigils" in player_card.card_data:
			new_sigs = player_card.card_data.sigils.duplicate()
		new_sigs.append("Stitched")
		player_card.card_data.sigils = new_sigs
		player_card.from_data(player_card.card_data)
		
		enemy_card.get_node("CardBody/Highlight").show()

		fightManager.move_done()


	if sig_name == "Energy Gun":

		if fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").visible:
			fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").take_damage(1)
			fightManager.move_done()
			return

		var player_card = get_friendly_card(card_slot)
		if not fightManager.enemy_no_energy_deplete:
			fightManager.set_opponent_energy(fightManager.opponent_energy - 1)

		player_card.take_damage(get_enemy_card(card_slot), 1)

	if sig_name == "Energy Sniper":

		if fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").visible:
			fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").take_damage(1)
			fightManager.move_done()
			return

		# Wait for snipe (no wait handle this with args)
#		var target = yield(fightManager, "snipe_complete")

		var player_card = get_friendly_card(arg)
		if not fightManager.enemy_no_energy_deplete:
			fightManager.set_opponent_energy(fightManager.opponent_energy - 1)

		player_card.take_damage(get_enemy_card(card_slot), 1)
		fightManager.move_done()

	#TODO: BACK
	if sig_name == "Energy Gun (Eternal)":

		if fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").visible:

			var dmg = min(fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").health, fightManager.opponent_energy)

			fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").take_damage(dmg)
			if not fightManager.enemy_no_energy_deplete:
				fightManager.set_opponent_energy(fightManager.opponent_energy - dmg)
			fightManager.move_done()
			return

		var player_card = player_slots[card_slot].get_child(0)
		var dmg = min(fightManager.opponent_energy, player_card.health)
		if not fightManager.enemy_no_energy_deplete:
			fightManager.set_opponent_energy(fightManager.opponent_energy - dmg)

		player_card.take_damage(get_enemy_card(card_slot), dmg)

	if sig_name == "Power Dice":
		if not fightManager.enemy_no_energy_deplete:
			fightManager.set_opponent_energy(fightManager.opponent_energy - 1)

		var diff = enemy_card.attack - enemy_card.card_data["attack"]

		enemy_card.card_data["attack"] = arg

		enemy_card.attack = arg + diff

		enemy_card.draw_stats()

	if sig_name == "Power Dice (2)":
		if not fightManager.enemy_no_energy_deplete:
			fightManager.set_opponent_energy(fightManager.opponent_energy - 2)

		var diff = enemy_card.attack - enemy_card.card_data["attack"]

		enemy_card.card_data["attack"] = arg

		enemy_card.attack = arg + diff

		enemy_card.draw_stats()

	if sig_name == "Enlarge":
		fightManager.add_opponent_bones(-2)
		enemy_card.health += 1

		enemy_card.card_data["attack"] += 1 # save attack to avoid bug
		enemy_card.attack += 1

		enemy_card.draw_stats()

	if sig_name == "Enlarge (3)":
		fightManager.add_opponent_bones(-2)
		enemy_card.health += 1

		enemy_card.card_data["attack"] += 1 # save attack to avoid bug
		enemy_card.attack += 1

		enemy_card.draw_stats()

	if sig_name == "Stimulate":
		if not fightManager.enemy_no_energy_deplete:
			fightManager.set_opponent_energy(fightManager.opponent_energy - 3)
		enemy_card.health += 1

		enemy_card.card_data["attack"] += 1 # save attack to avoid bug
		enemy_card.attack += 1

		enemy_card.draw_stats()

	if sig_name == "Stimulate (4)":
		if not fightManager.enemy_no_energy_deplete:
			fightManager.set_opponent_energy(fightManager.opponent_energy - 4)
		enemy_card.health += 1

		enemy_card.card_data["attack"] += 1 # save attack to avoid bug
		enemy_card.attack += 1

		enemy_card.draw_stats()

	if sig_name == "Bonehorn":
		if not fightManager.enemy_no_energy_deplete:
			fightManager.set_opponent_energy(fightManager.opponent_energy - 1)
		fightManager.add_opponent_bones(3)
	if sig_name == "Bonehorn (1)":
		if not fightManager.enemy_no_energy_deplete:
			fightManager.set_opponent_energy(fightManager.opponent_energy - 1)
		fightManager.add_opponent_bones(1)

	if sig_name == "Disentomb":
		fightManager.add_opponent_bones(-1)

	if sig_name == "Disentomb (Corpses)":
		fightManager.add_opponent_bones(-2)


#	Only animate if not dying
	if not "Perish" in enemy_card.get_node("AnimationPlayer").current_animation:
		enemy_card.get_node("AnimationPlayer").play("ProcGeneric")
		yield(enemy_card.get_node("AnimationPlayer"), "animation_finished")

	fightManager.move_done()


func remote_card_data(card_slot, new_data):
	var card = get_enemy_card(card_slot)
	card.from_data(new_data)

	# Calculate buffs
	for fCard in all_friendly_cards():
		fCard.calculate_buffs()
	for eCard in all_enemy_cards():
		eCard.calculate_buffs()

	# Hide tentacle atk symbol
	card.get_node("CardBody/AtkIcon").visible = false
	card.get_node("CardBody/AtkScore").visible = true

	fightManager.move_done()

func handle_enemy_attack(from_slot, to_slot):

	print("handling enemy attack!")

	var enemy_card = get_enemy_card(from_slot)

	# Special moon logic
	if fightManager.get_node("MoonFight/BothMoons/EnemyMoon").visible:
		# This means they're hitting something with the moon

		var moon = fightManager.get_node("MoonFight/BothMoons/EnemyMoon")

		if fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").visible:
			fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").take_damage(moon.attack)
			return
		elif moon.target >= 0:
#			player_slots[moon.target].get_child(0).take_damage(null, moon.attack)
			to_slot = moon.target
			enemy_card = moon
		else:
			fightManager.inflict_damage(-moon.attack)
			return

	if fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").visible:
		# This means they're attacking your moon

		fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").take_damage(
			enemy_slots[from_slot].get_child(0).attack
		)
		return
		
#	var attack_targeting = SigilEffect.AttackTargeting.SCALE if is_slot_empty(player_slots[to_slot]) else SigilEffect.AttackTargeting.CARD
#
#	#var direct_attack = false
#
	var player_card = null
#
#
#	for playerCard in all_friendly_cards():
#		for sig in playerCard.grouped_sigils[SigilEffect.SigilTriggers.PRE_ENEMY_ATTACK]:
#			# I put the mole logic in here!
#			sig.pre_enemy_attack(eCard, to_slot, attack_targeting)
	
	if not is_slot_empty(player_slots[to_slot]):
		player_card = player_slots[to_slot].get_child(0)
	
	var attack_targeting = get_attack_targeting(false, enemy_card, player_card)

#	var direct_attack = false
#
#	var pCard = null
#
#	if is_slot_empty(player_slots[to_slot]):
#		direct_attack = true
#
#		# Check for moles
#		# Mole man
#		if eCard.has_sigil("Airborne"):
#			for card in all_friendly_cards():
#				if card.has_sigil("Burrower") and card.has_sigil("Mighty Leap"):
#					direct_attack = false
#					card.move_to_parent(player_slots[to_slot])
#					pCard = card
#					break
#		else: # Regular mole
#			for card in all_friendly_cards():
#				if card.has_sigil("Burrower"):
#					direct_attack = false
#					card.move_to_parent(player_slots[to_slot])
#					pCard = card
#					break
#	else:
#		pCard = player_slots[to_slot].get_child(0)
#		if eCard.has_sigil("Airborne") and not pCard.has_sigil("Mighty Leap"):
#			direct_attack = true
#		if pCard.get_node("CardBody/DiveOlay").visible:
#			direct_attack = true
	
	# Special: Sniper is assumed to be attacking directly if it has no target
	if enemy_card.has_sigil("Sniper") and is_slot_empty(player_slots[fightManager.sniper_targets[0]]):
		attack_targeting = SigilEffect.AttackTargeting.SCALE


	if attack_targeting == SigilEffect.AttackTargeting.SCALE:
#		fightManager.inflict_damage(-eCard.attack)
		fightManager.inflict_damage(-1 if "atkspecial" in enemy_card.card_data and CardInfo.all_data.variable_attack_nerf else -enemy_card.attack)

	elif attack_targeting == SigilEffect.AttackTargeting.CARD:
		player_card.take_damage(enemy_card)

	else:
		pass

# Something for tri strike effect
remote func set_card_offset(card_slot, offset):
	if is_slot_empty(enemy_slots[card_slot]):
		return

	if card_slot < nLanes - 1:
		if offset > 0:
			enemy_slots[card_slot + 1].show_behind_parent = true
		else:
			enemy_slots[card_slot + 1].show_behind_parent = false

	enemy_slots[card_slot].get_child(0).rect_position.x = offset


# SPECIAL: Use a candle
func _on_Snuff_pressed():

	print("SNUFFY")

	if fightManager.state != fightManager.GameStates.NORMAL:
		return

	if fightManager.lives > 1 and CardInfo.all_data.allow_snuffing_candles:
		fightManager.inflict_damage(-10)
		fightManager.damage_stun = false
		
		var snuffCardData = null
		if "snuff_card" in CardInfo.all_data:
			snuffCardData = CardInfo.from_name(CardInfo.all_data.snuff_card)
		else:
			snuffCardData = CardInfo.from_name("Greater Smoke")
		
		if snuffCardData == null:
			snuffCardData = {
				"name": "Greater Smoke",
				"sigils": ["Bone King"],
				"attack": 1,
				"health": 3,
				"banned": true,
				"rare": true,
				"description": "Ported from Act 1. Act 2 sprite by syntaxevasion."
			}
		fightManager.draw_card(snuffCardData)
		
		fightManager.send_move({
			"type": "snuff_candle"
		})

#why did no one bother to add something for this?
#SERIOUSLY? those last four lines of code, in that exact order, were EVERYWHERE!
func recalculate_buffs_and_such():
	#calcuate conduits

	#it turns out, all you REALLY need to do for conduit shit is to calculate the rightmost and leftmost conduits,
	#because any conduit in the middle will complete a circuit with the outermost conduit on either side.
	
	#it pains me that these values need to be hardcoded... for now
	#I have big plans
	friendly_conduit_data = [-1, -1]
	enemy_conduit_data = [-1, -1]
	
	for sIdx in range(4): #replace 4 with max rows
		if not is_slot_empty(player_slots[sIdx]):
			if "conduit" in player_slots[sIdx].get_child(0).card_data:
				if friendly_conduit_data[0] == -1:
					friendly_conduit_data[0] = sIdx
				friendly_conduit_data[1] = sIdx
		if not is_slot_empty(enemy_slots[sIdx]):
			if "conduit" in enemy_slots[sIdx].get_child(0).card_data:
				if enemy_conduit_data[0] == -1:
					enemy_conduit_data[0] = sIdx
				enemy_conduit_data[1] = sIdx

	#calculate buffs and such

	for card in all_friendly_cards():
		card.calculate_buffs()
	for eCard in all_enemy_cards():
		eCard.calculate_buffs()


# Conduit madness
#no longer used tmk, -WhiteRobot10
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
	for sIdx in range(slot_idx + 1, nLanes):
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

#no longer used tmk, -WhiteRobot10
func get_conduitfx_friendly(slot_idx):

	var slots = player_slots

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
	for sIdx in range(slot_idx + 1, nLanes):
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

#no longer used tmk, -WhiteRobot10
func get_conduitfx_enemy(slot_idx):

	var slots = enemy_slots

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
	for sIdx in range(slot_idx + 1, nLanes):
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


# Shifting
func shift_cards_forward(friendly):
	for card in all_friendly_cards_backrow() if friendly else all_enemy_cards_backrow():
		card.move_to_parent(
			player_slots[card.slot_idx()] if friendly else enemy_slots[card.slot_idx()]
		)


# New Helper functions
func get_friendly_card(slot_idx):

	if slot_idx > nLanes - 1 or slot_idx < 0:
		return false

	for card in player_slots[slot_idx].get_children():
		if not "Perish" in card.get_node("AnimationPlayer").current_animation:
			return card
	return false

func get_enemy_card(slot_idx):

	if slot_idx > nLanes - 1 or slot_idx < 0:
		return false

	for card in enemy_slots[slot_idx].get_children():
		if not "Perish" in card.get_node("AnimationPlayer").current_animation:
			return card
	return false

func all_friendly_cards():
	var cards = []

	for slot_idx in range(nLanes):
		if not is_slot_empty(player_slots[slot_idx]):
			cards.append(get_friendly_card(slot_idx))

	return cards

func all_friendly_cards_backrow():
	var cards = []

	for slot in player_slots_back:
		if not is_slot_empty(slot):
			cards.append(slot.get_child(0))

	return cards

func all_enemy_cards():
	var cards = []

	for slot_idx in range(nLanes):
		if not is_slot_empty(enemy_slots[slot_idx]):
			cards.append(get_enemy_card(slot_idx))

	return cards

func all_enemy_cards_backrow():
	var cards = []

	for slot in enemy_slots_back:
		if not is_slot_empty(slot):
			cards.append(slot.get_child(0))

	return cards

func is_slot_empty(slot):
	if slot.get_child_count():
		for ch in slot.get_children():
			if ch.is_alive():
				return false

	return true
