extends VBoxContainer


onready var playerSlots = $PlayerSlots.get_children()
onready var enemySlots = $EnemySlots.get_children()
onready var fightManager = get_node("/root/Main/CardFight")
onready var handManager = fightManager.get_node("HandsContainer/Hands")

# Cards selected for sacrifice
var sacVictims = []

# Combat handling
var current_attacker = -1

func clear_slots():
	for slot in playerSlots:
		if slot.get_child_count() > 0:
			slot.get_child(0).queue_free()

func get_available_blood() -> int:
	var blood = 0
	
	for slot in playerSlots:
		if slot.get_child_count() > 0:
			blood += 1
	
	return blood

func clear_sacrifices():
	for victim in sacVictims:
		victim.get_node("CardBody/SacOlay").visible = false
		rpc_id(fightManager.opponent, "set_sac_olay_vis", victim.get_parent().get_position_in_parent(), false)
	
	sacVictims.clear()

# Test if a sacrifice can be made
func is_sacrifice_possible(card_to_summon):
	if get_available_blood() < card_to_summon.card_data["blood_cost"]:
		return false

func attempt_sacrifice():
	if len(sacVictims) >= handManager.raisedCard.card_data["blood_cost"]:
		# Kill sacrifical victims
		for victim in sacVictims:
			victim.get_node("AnimationPlayer").play("Sacrifice")
			rpc_id(fightManager.opponent, "remote_card_anim", victim.get_parent().get_position_in_parent(), "Sacrifice")
		sacVictims.clear()
		
		# Force player to summon the new card
		fightManager.state = fightManager.GameStates.FORCEPLAY

func initiate_combat():
	# Don't allow ending turn in forceplay state
	if fightManager.state in [fightManager.GameStates.FORCEPLAY]:
		return
	
	current_attacker = 0
	
	while current_attacker < 4:
		if playerSlots[current_attacker].get_child_count() > 0:
			playerSlots[current_attacker].get_child(0).attack_pass()
			break
		current_attacker += 1
	
	if current_attacker == 4:
		fightManager.end_turn()


# This is called at the end of a card's attack animation
func attack_callback():
	# Increment current attacker
	current_attacker += 1
	
	# If final attacker has already attacked, end turn
	if current_attacker == 4:
		fightManager.end_turn()
	else:
		while current_attacker < 4:
			if playerSlots[current_attacker].get_child_count() > 0:
				playerSlots[current_attacker].get_child(0).attack_pass()
				break
			current_attacker += 1
		
		if current_attacker == 4:
			fightManager.end_turn()
		

# Do the attack damage
func handle_attack(slot_index):
	print("Attack in progress from slot ", slot_index)
	
	# Is there an opposing card to attack?
	if enemySlots[slot_index].get_child_count() > 0:
		print("Attack hits enemy card!")
		var eCard = enemySlots[slot_index].get_child(0)
		eCard.health -= playerSlots[slot_index].get_child(0).attack
		eCard.draw_stats()
		if eCard.health <= 0:
			eCard.get_node("AnimationPlayer").play("Perish")
		
	else:
		var dmg = playerSlots[slot_index].get_child(0).attack
		print("Direct attack for ", dmg, " damage!")
		fightManager.inflict_damage(dmg)
	
	rpc_id(fightManager.opponent, "handle_enemy_attack", slot_index)
	

# Remote
remote func set_sac_olay_vis(slot, vis):
	enemySlots[slot].get_child(0).get_node("CardBody/SacOlay").visible = vis

remote func sacrifice_card(slot):
	enemySlots[slot].get_child(0).get_node("AnimationPlayer").play("Sacrifice")

remote func remote_card_anim(slot, anim_name):
	enemySlots[slot].get_child(0).get_node("AnimationPlayer").play(anim_name)
	
remote func handle_enemy_attack(slot_index):
	print("Attack in progress from enemy slot ", slot_index)
	
	# Is there an opposing card to attack?
	if playerSlots[slot_index].get_child_count() > 0:
		print("Attack hits friendly card!")
		var pCard = playerSlots[slot_index].get_child(0)
		pCard.health -= enemySlots[slot_index].get_child(0).attack
		pCard.draw_stats()
		if pCard.health <= 0:
			pCard.get_node("AnimationPlayer").play("Perish")
		
	else:
		var dmg = enemySlots[slot_index].get_child(0).attack
		print("Enemy attacks directly for ", dmg, " damage!")
		fightManager.inflict_damage(-dmg)
		
