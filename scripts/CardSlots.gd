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
	if len(sacVictims) >= handManager.raisedCard.card_data["blood_cost"]:
		# Kill sacrifical victims
		for victim in sacVictims:
			if "Many Lives" in victim.card_data["sigils"]:
				victim.get_node("AnimationPlayer").play("CatSac")
				rpc_id(fightManager.opponent, "remote_card_anim", victim.get_parent().get_position_in_parent(), "CatSac")
			else:
				victim.get_node("AnimationPlayer").play("Perish")
				rpc_id(fightManager.opponent, "remote_card_anim", victim.get_parent().get_position_in_parent(), "Perish")
				fightManager.add_bones(1)
			
				# SIGILS
				## Unkillable
				if "Unkillable" in victim.card_data["sigils"]:
					fightManager.draw_card(allCards.all_cards.find(victim.card_data))
			
		sacVictims.clear()
		
		# Force player to summon the new card
		fightManager.state = fightManager.GameStates.FORCEPLAY

# Combat
func initiate_combat():
	for slot in playerSlots:
		if slot.get_child_count() > 0 and slot.get_child(0).attack > 0:
			
			var pCard = slot.get_child(0)
			var cardAnim = pCard.get_node("AnimationPlayer")
			var slot_index = slot.get_position_in_parent()
			
			
			if "Trifurcated Strike" in pCard.card_data["sigils"]:
				# Lower slot to right for attack anim (JANK AF)
				if slot_index < 3:
					playerSlots[slot_index + 1].show_behind_parent = true
				
				# Tri strike attack
				for s_offset in range(-1, 2):
					# Prevent attacking out of bounds
					var atk_slot = slot_index + s_offset
					if atk_slot < 0 or atk_slot > 3:
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
				cardAnim.play("Attack")
				rpc_id(fightManager.opponent, "remote_card_anim", slot.get_position_in_parent(), "AttackRemote")
				yield(cardAnim, "animation_finished")
		
	fightManager.end_turn()


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
	
	if direct_attack:
		fightManager.inflict_damage(pCard.attack)
	else:
		eCard.health -= pCard.attack
		eCard.draw_stats()
		if eCard.health <= 0 or "Touch of Death" in pCard.card_data["sigils"]:
			eCard.get_node("AnimationPlayer").play("Perish")
			fightManager.add_opponent_bones(1)
	
	rpc_id(fightManager.opponent, "handle_enemy_attack", from_slot, to_slot)

# Sigil handling
func has_friendly_sigil(sigil):
	for slot in playerSlots:
		if slot.get_child_count() > 0:
			if sigil in slot.get_child(0).card_data["sigils"]:
				return true
	
	return false

# Remote
remote func set_sac_olay_vis(slot, vis):
	enemySlots[slot].get_child(0).get_node("CardBody/SacOlay").visible = vis


remote func remote_card_anim(slot, anim_name):
	enemySlots[slot].get_child(0).get_node("AnimationPlayer").stop()
	enemySlots[slot].get_child(0).get_node("AnimationPlayer").play(anim_name)
	
	if anim_name == "Perish":
		fightManager.add_opponent_bones(1)


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
	
	if direct_attack:
		fightManager.inflict_damage(-eCard.attack)
	else:
		pCard.health -= eCard.attack
		pCard.draw_stats()
		if pCard.health <= 0 or "Touch of Death" in eCard.card_data["sigils"]:
			pCard.get_node("AnimationPlayer").play("Perish")
			fightManager.add_bones(1)

# Something for tri strike effect
remote func set_card_offset(card_slot, offset):
	if card_slot < 3:
		if offset > 0:
			enemySlots[card_slot + 1].show_behind_parent = true
		else:
			enemySlots[card_slot + 1].show_behind_parent = false
	
	enemySlots[card_slot].get_child(0).rect_position.x = offset
