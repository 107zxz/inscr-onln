extends Control

onready var deckContainer = get_node("/root/Main/DeckEdit/HBoxContainer/VBoxContainer/MainArea/VBoxContainer/DeckPreview/DeckContainer")
onready var previewCont = get_node("/root/Main/DeckEdit/HBoxContainer/CardPreview/PreviewContainer/")

onready var sigilDescPrefab = preload("res://packed/SigilDescription.tscn")
onready var fightManager = get_node("/root/Main/CardFight")
onready var slotManager = get_node("/root/Main/CardFight/CardSlots")

var paperTheme = preload("res://themes/papertheme.tres")

# State
var card_data = {}
var in_hand = true

# Stats
var health = -1
var attack = -1

# New sigils
var sigils = []

# Sigil-specific information (must be stored per-card)
var strike_offset = 0 # Used for tri strike, stores which slot the card should attack relative to itself
var sprint_left = false # Used for sprinter
var sacrifice_count = 0

func from_data(cdat):
	card_data = cdat.duplicate()

	$CardBody.draw_from_data(card_data)
	
	# Set stats
	attack = card_data["attack"]
	health = card_data["health"]
	draw_stats()
	
	# Enable interaction with the card
	$CardBody/Button.disabled = false
	
func create_sigils(friendly):
	if not "sigils" in card_data:
		return
		
	for sig in card_data.sigils:
		var sigPath = "res://scripts/classes/sigils/" + sig + ".gd"
		
		if not ResourceLoader.exists(sigPath):
			print("Missing sigil " + sig)
			continue
		
		print("Adding sigil " + sig)
		
		var ns = load(sigPath).new()
		ns.fightManager = fightManager
		ns.slotManager = slotManager
		ns.card = self
		ns.isFriendly = friendly
		sigils.append(ns)

func handle_sigil_event(event, params):
	for sig in sigils:
		sig.handle_event(event, params)

func draw_stats():
	$CardBody/HBoxContainer/AtkScore.text = str(attack)
	$CardBody/HBoxContainer/HpScore.text = str(health)

# When card is clicked
func _on_Button_pressed():

	fightManager.replay.record_action({"type": "card_clicked", "slot": slot_idx()})

	# Only allow raising while in hand
	if in_hand:

		# Turn off hammer if it's on
		if fightManager.state == fightManager.GameStates.HAMMER:
			fightManager.hammer_mode()
			# Jank workaround
			fightManager.get_node("LeftSideUI/HammerButton").pressed = false

		# Disable hand interactions while in a non-interactable phase
		if not fightManager.state in [fightManager.GameStates.NORMAL, fightManager.GameStates.SACRIFICE]:
			return
		
		if self == get_parent().get_parent().raisedCard:
			lower()
			get_parent().get_parent().raisedCard = null
			fightManager.state = fightManager.GameStates.NORMAL
			
			# Clear sacrifices
			for card in slotManager.sacVictims:
				card.get_node("CardBody/SacOlay").visible = false
				slotManager.rpc_id(fightManager.opponent, "set_sac_olay_vis", card.slot_idx(), $CardBody/SacOlay.visible)
			
			slotManager.sacVictims = []

		elif in_hand:
			
			# Only raise if all costs are met
			if "bone_cost" in card_data and fightManager.bones < card_data["bone_cost"]:
				print("You need more bones!")
				return
				
			if "energy_cost" in card_data and fightManager.energy < card_data["energy_cost"]:
				print("You need more energy!")
				return
			
			if "blood_cost" in card_data and slotManager.get_available_blood() < card_data["blood_cost"]:
				print("You need more sacrifices!")
				return
			
			if "mox_cost" in card_data and not slotManager.get_friendly_cards_sigil("Great Mox"):
				for mox in card_data["mox_cost"]:
					if not slotManager.get_friendly_cards_sigil(mox + " Mox"):
						print(mox + " Mox missing")
						return
			
			# Check there's a free slot to play me in (if not blood)\
			if not "blood_cost" in card_data and slotManager.get_available_slots() == 0:
				print("No room to play")
				return
			
			# Enter sacrifice mode if card needs sacs
			if "blood_cost" in card_data:
				fightManager.state = fightManager.GameStates.SACRIFICE
			else:
				fightManager.state = fightManager.GameStates.NORMAL
			
			raise()
	
	# When on board
	else:
		# Don't allow spam saccing
		if $AnimationPlayer.is_playing():
			return
		
		# Is it hammer time? Am I on the player's side?
		if fightManager.state == fightManager.GameStates.HAMMER and get_parent().get_parent().name == "PlayerSlots" and not "nohammer" in card_data:
			$AnimationPlayer.play("Perish")
			slotManager.rpc_id(fightManager.opponent, "remote_card_anim", get_parent().get_position_in_parent(), "Perish")
			
			# Always turn off hammer after hammering something (requested)
			fightManager.hammer_mode()
			# Jank workaround
			fightManager.get_node("LeftSideUI/HammerButton").pressed = false

			if "hammers_per_turn" in CardInfo.all_data:
				fightManager.hammers_left -= 1

				fightManager.get_node("LeftSideUI/HammerButton").text = "Hammer (%d/%d)" % [fightManager.hammers_left, CardInfo.all_data.hammers_per_turn]

				if fightManager.hammers_left <= 0:
					fightManager.get_node("LeftSideUI/HammerButton").disabled = true
		
		# Am I about to be sacrificed
		if fightManager.state == fightManager.GameStates.SACRIFICE:
			if self in slotManager.sacVictims:
				slotManager.sacVictims.erase(self)
				$CardBody/SacOlay.visible = false
			else:
				
				# How tf did this not get patched 6 months ago
				if get_parent().get_parent().name != "PlayerSlots":
					print("Nice try dumbass!")
					return
				
				# Make sure we're not about to catbrick
				var brick = true
				
				if slotManager.get_available_slots() == 0 and has_sigil("Many Lives"):
					for vic in slotManager.sacVictims:
						if not vic.has_sigil("Many Lives"):
							brick = false
							break
				else:
					brick = false
				
				if brick:
					return
				
				# Don't allow sacrificing nosac cards
				if "nosac" in card_data:
					return
				
				slotManager.sacVictims.append(self)
				$CardBody/SacOlay.visible = true
				
				# Attempt a sacrifice
				slotManager.attempt_sacrifice()
				
			slotManager.rpc_id(fightManager.opponent, "set_sac_olay_vis", slot_idx(), $CardBody/SacOlay.visible)

# Animation
func raise():
	get_parent().get_parent().lower_all_cards()
	get_parent().get_parent().raisedCard = self
	
	$AnimationPlayer.play("Raise")
	
	# Show the opponent the card was raised
	get_parent().get_parent().rpc_id(fightManager.opponent, "raise_opponent_card", get_position_in_parent())
	
func lower():
	if self == get_parent().get_parent().raisedCard:
		$AnimationPlayer.play("Lower")
		
		get_parent().get_parent().rpc_id(fightManager.opponent, "lower_opponent_card", get_position_in_parent())	

# Move to origin of new parent
func move_to_parent(new_parent):
	var from_hand = false
	var moved = true

	if new_parent == get_parent():
		moved = false

	# Get card out of hand if possible, and ensure it is not considered raised
	if new_parent.name != "PlayerHand":
		in_hand = false
	
	# Lower cards if just played by active player
	if get_parent().name in [ "PlayerHand", "EnemyHand" ]:
		get_parent().get_parent().lower_all_cards()
		from_hand = true
	
	# Reset position, as expected to be raised when this happens
	$AnimationPlayer.play("RESET")
	
	var gPos = rect_global_position
	get_parent().remove_child(self)
	new_parent.add_child(self)
	
	rect_position = Vector2.ZERO
	$CardBody.rect_global_position = gPos
	
	if not moved:
		$Tween.interpolate_property($CardBody, "rect_position", $CardBody.rect_position, Vector2.ZERO, 0.01, Tween.TRANS_LINEAR)
		$Tween.start()
		return
	
	$Tween.interpolate_property($CardBody, "rect_position", $CardBody.rect_position, Vector2.ZERO, 0.1, Tween.TRANS_LINEAR)
	$Tween.start()

	# Sentry stuff
	if new_parent.get_parent().name == "PlayerSlots":
		var eCard = null
		if not slotManager.is_slot_empty(slotManager.enemySlots[new_parent.get_position_in_parent()]):
			eCard = slotManager.enemySlots[new_parent.get_position_in_parent()].get_child(0)
			if eCard.has_sigil("Sentry"):
				take_damage(eCard, 1)
		
		# I am the sentry
		# Activate when moved
		if has_sigil("Sentry") and not from_hand:
			if eCard:
				eCard.take_damage(self, 1)
		
		# Special atk stats
		if "atkspecial" in card_data:
			$CardBody/AtkIcon.visible = false
			$CardBody/HBoxContainer/AtkScore.visible = true

	if new_parent.get_parent().name == "EnemySlots":
		var pCard = null
		if not slotManager.is_slot_empty(slotManager.playerSlots[new_parent.get_position_in_parent()]):
			pCard = slotManager.playerSlots[new_parent.get_position_in_parent()].get_child(0)
			if pCard.has_sigil("Sentry"):
				take_damage(pCard, 1)

		# I am the sentry
		# Activate when moved
		if has_sigil("Sentry") and not from_hand:
			if pCard:
				pCard.take_damage(self, 1)
		
		# Green Mage
		if "atkspecial" in card_data:
			$CardBody/AtkIcon.visible = false
			$CardBody/HBoxContainer/AtkScore.visible = true
	


# This is called when the attack animation would "hit". tell the slot manager to make it happen
func attack_hit():
	slotManager.handle_attack(get_parent().get_position_in_parent(), get_parent().get_position_in_parent() + strike_offset)

# Called when the card starts dying. Add bones and stuff
func begin_perish(doubleDeath = false):
	
	# For necro
	var canRespawn = true
	
	if get_parent().get_parent().name == "PlayerSlots":
		if doubleDeath:
			fightManager.card_summoned(self)

		if has_sigil("Bone King"):
			fightManager.add_bones(4)
		elif not has_sigil("Boneless"):
			fightManager.add_bones(1)
			
		# Temp
		if "necro_boned" in CardInfo.all_data and slotManager.get_friendly_cards_sigil("Double Death") and slotManager.get_friendly_cards_sigil("Double Death")[0] != self:
			if has_sigil("Bone King"):
				fightManager.add_bones(4)
			elif not has_sigil("Boneless"):
				fightManager.add_bones(1)
				
		## SIGILS
		# Ruby Heart
		if has_sigil("Ruby Heart"):
			slotManager.rpc_id(fightManager.opponent, "remote_card_summon", CardInfo.from_name("Ruby Mox"), get_parent().get_position_in_parent())
			slotManager.summon_card(CardInfo.from_name("Ruby Mox"), get_parent().get_position_in_parent())
			canRespawn = false

		# Frozen Away
		if has_sigil("Frozen Away"):
			slotManager.rpc_id(fightManager.opponent, "remote_card_summon", CardInfo.from_name("Skeleton"), get_parent().get_position_in_parent())
			slotManager.summon_card(CardInfo.from_name("Skeleton"), get_parent().get_position_in_parent())
			canRespawn = false

		# Unkillable
		if has_sigil("Unkillable"):
			fightManager.draw_card(card_data)
		
		# Reconstitute
		if has_sigil("Reconstitute"):

			if card_data["name"] == "Ouroboros":
				card_data["attack"] += 1
				card_data["health"] += 1
			
			fightManager.gold_sarcophagus.append(
				{
					"card": card_data,
					"turnsleft": 1
				}
			)
		
		# Gem dependent (not this card)
		if "sigils" in card_data:
			for sigil in card_data["sigils"]:
				if "Mox" in sigil:

					# Any Mox dying tests gem dependant
					var kill = not (slotManager.get_friendly_cards_sigil("Great Mox"))

					for moxcol in ["Green", "Blue", "Orange"]:
						for foundMox in slotManager.get_friendly_cards_sigil(moxcol + " Mox"):
							if foundMox != self:
								kill = false;
								break
					
					if kill:
						for gDep in slotManager.get_friendly_cards_sigil("Gem Dependant"):
							gDep.get_node("AnimationPlayer").play("Perish")
							slotManager.rpc_id(fightManager.opponent, "remote_card_anim", gDep.get_parent().get_position_in_parent(), "Perish")
				break
			
		# Explosive motherfucker
		if has_sigil("Detonator"):

			var slotIdx = get_parent().get_position_in_parent()

			# Attack the moon
			if fightManager.get_node("MoonFight/BothMoons/EnemyMoon").visible:

				fightManager.get_node("MoonFight/BothMoons/EnemyMoon").take_damage(5)

			elif slotIdx > 0 and not slotManager.is_slot_empty(slotManager.playerSlots[slotIdx - 1]):
				var eCard = slotManager.playerSlots[slotIdx - 1].get_child(0)

				if eCard.get_node("AnimationPlayer").current_animation != "Perish":
					eCard.take_damage(self, 5)
#					eCard.health -= 5
#					if eCard.health <= 0:
#						eCard.get_node("AnimationPlayer").play("Perish")
#						slotManager.rpc_id(fightManager.opponent, "remote_card_anim", slotIdx - 1, "Perish")
#					else:
#						eCard.draw_stats()
#						slotManager.rpc_id(fightManager.opponent, "remote_card_stats", slotIdx - 1, eCard.attack, eCard.health)

			if slotIdx < 3 and not slotManager.is_slot_empty(slotManager.playerSlots[slotIdx + 1]):
				var eCard = slotManager.playerSlots[slotIdx + 1].get_child(0)

				if eCard.get_node("AnimationPlayer").current_animation != "Perish":
					eCard.take_damage(self, 5)
#					eCard.health -= 5
#					if eCard.health <= 0:
#						eCard.get_node("AnimationPlayer").play("Perish")
#						slotManager.rpc_id(fightManager.opponent, "remote_card_anim", slotIdx + 1, "Perish")
#					else:
#						eCard.draw_stats()
#						slotManager.rpc_id(fightManager.opponent, "remote_card_stats", slotIdx + 1, eCard.attack, eCard.health)

			if not slotManager.is_slot_empty(slotManager.enemySlots[slotIdx]):
				var eCard = slotManager.get_enemy_card(slotIdx)
				
				if eCard.get_node("AnimationPlayer").current_animation != "Perish":
					eCard.take_damage(self, 5)

		# Remove Energy Conduit Buff
		if has_sigil("Energy Conduit"):
			print("Removing buff")
			fightManager.max_energy_buff = 0
			fightManager.set_max_energy(fightManager.max_energy)
			fightManager.set_energy(min(fightManager.energy, fightManager.max_energy))
			
		# Get everyone to recalculate buffs (a card died)
		for card in slotManager.all_friendly_cards():
			card.calculate_buffs()

		for eCard in slotManager.all_enemy_cards():
			eCard.calculate_buffs()

		# Play the special animation if necro is in play
		if not doubleDeath and slotManager.get_friendly_cards_sigil("Double Death") and slotManager.get_friendly_cards_sigil("Double Death")[0] != self and not "necro_boned" in CardInfo.all_data:
			# Don't do it if I spawn a card on death
			if canRespawn:
				$AnimationPlayer.play("DoublePerish")
			return

	else:
		if has_sigil("Bone King"):
			fightManager.add_opponent_bones(4)
		elif not has_sigil("Boneless"):
			fightManager.add_opponent_bones(1)
		
		# Temp
		if "necro_boned" in CardInfo.all_data and slotManager.get_enemy_cards_sigil("Double Death") and slotManager.get_enemy_cards_sigil("Double Death")[0] != self:
			if has_sigil("Bone King"):
				fightManager.add_opponent_bones(4)
			elif not has_sigil("Boneless"):
				fightManager.add_opponent_bones(1)
		
		# Explosive motherfucker
		if has_sigil("Detonator"):

			var slotIdx = get_parent().get_position_in_parent()

			# Attack the moon
			if fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").visible:

				fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").take_damage(5)

			elif not slotManager.is_slot_empty(slotManager.playerSlots[slotIdx]):
				var eCard = slotManager.playerSlots[slotIdx].get_child(0)

				if eCard.get_node("AnimationPlayer").current_animation != "Perish":
					eCard.take_damage(self, 5)
#					eCard.health -= 5
#					if eCard.health <= 0:
#						eCard.get_node("AnimationPlayer").play("Perish")
#						slotManager.rpc_id(fightManager.opponent, "remote_card_anim", slotIdx, "Perish")
#					else:
#						eCard.draw_stats()
#						slotManager.rpc_id(fightManager.opponent, "remote_card_stats", slotIdx, eCard.attack, eCard.health)
#
		# Energy conduit buff
		if has_sigil("Energy Conduit"):
			print("Removing enemy buff")
			fightManager.opponent_max_energy_buff = 0
			fightManager.set_opponent_max_energy(fightManager.opponent_max_energy)
			fightManager.set_opponent_energy(min(fightManager.opponent_energy, fightManager.opponent_max_energy))
		
		# Get everyone to recalculate buffs (a card died)
		for card in slotManager.all_friendly_cards():
			card.calculate_buffs()

		for eCard in slotManager.all_enemy_cards():
			eCard.calculate_buffs()

		# Play the special animation if necro is in play
		if not doubleDeath and slotManager.get_enemy_cards_sigil("Double Death") and slotManager.get_enemy_cards_sigil("Double Death")[0] != self and not "necro_boned" in CardInfo.all_data:
			$AnimationPlayer.play("DoublePerish")
			return


# This is called when a card evolves with the fledgling sigil
func evolve():
	var dmgTaken = card_data["health"] - health

	from_data(CardInfo.from_name(card_data["evolution"]))

	health = card_data["health"] - dmgTaken

	# Calculate buffs
	for card in slotManager.all_friendly_cards():
		card.calculate_buffs()
	for eCard in slotManager.all_enemy_cards():
		eCard.calculate_buffs()


func _on_ActiveSigil_pressed():

	# Sigil Effects
	var sName = card_data["sigils"][0]
	
	if sName == "True Scholar":
		if not slotManager.get_friendly_cards_sigil("Blue Mox") and not slotManager.get_friendly_cards_sigil("Great Mox"):
			return

		for _i in range(3):
			if fightManager.deck.size() == 0:
				break
			
			fightManager.draw_card(fightManager.deck.pop_front())
			
			# Some interaction here if your deck has less than 3 cards. Don't punish I guess?
			if fightManager.deck.size() == 0:
				fightManager.get_node("DrawPiles/YourDecks/Deck").visible = false
				break

		$AnimationPlayer.play("Perish")
		$CardBody/VBoxContainer/HBoxContainer/ActiveSigil.disabled = true
		$CardBody/VBoxContainer/HBoxContainer/ActiveSigil.mouse_filter = MOUSE_FILTER_IGNORE
		slotManager.rpc_id(fightManager.opponent, "remote_activate_sigil", get_parent().get_position_in_parent(), attack)
		return

	if sName == "Energy Gun":
		if fightManager.energy < 1:
			return
		
		if slotManager.is_slot_empty(slotManager.enemySlots[get_parent().get_position_in_parent()]) and not fightManager.get_node("MoonFight/BothMoons/EnemyMoon").visible:
			return
		
		var eCard = slotManager.enemySlots[get_parent().get_position_in_parent()].get_child(0)
		fightManager.set_energy(fightManager.energy - 1)
		
		if fightManager.get_node("MoonFight/BothMoons/EnemyMoon").visible:
			fightManager.get_node("MoonFight/BothMoons/EnemyMoon").take_damage(1)
		else:
			eCard.take_damage(self, 1)

	if sName == "Power Dice":
		if fightManager.energy < 2:
			return
		
		fightManager.set_energy(fightManager.energy - 2)
		
		attack = randi() % 6 + 1
		card_data["attack"] = attack
		draw_stats()
		
	if sName == "Enlarge":
		if fightManager.bones < 2:
			return
	
		fightManager.add_bones(-2)
		health += 1
		card_data.attack += 1 # Save attack to avoid deletion later
		attack += 1
			
		draw_stats()
	
	if sName == "Stimulate":
		if fightManager.energy < 4:
			return
	
		fightManager.set_energy(fightManager.energy - 4)
		health += 1
		card_data.attack += 1 # Save attack to avoid deletion later
		attack += 1
		
		draw_stats()
	
	if sName == "Bonehorn":
		if fightManager.energy < 1:
			return
	
		fightManager.set_energy(fightManager.energy - 1)
		fightManager.add_bones(1)
	
	if sName == "Disentomb":
		if fightManager.bones < 1:
			return

		fightManager.add_bones(-1)
		fightManager.draw_card(CardInfo.from_name("Withered Corpse"))
	
	# Disable button until start of next turn
	if false and fightManager.gameSettings.optActives:
		$CardBody/VBoxContainer/HBoxContainer/ActiveSigil.disabled = true
		$CardBody/VBoxContainer/HBoxContainer/ActiveSigil.mouse_filter = MOUSE_FILTER_IGNORE
	
	# Play anim and activate remotely
	if not "Perish" in $AnimationPlayer.current_animation:
		$AnimationPlayer.play("ProcGeneric")
	slotManager.rpc_id(fightManager.opponent, "remote_activate_sigil", get_parent().get_position_in_parent(), attack)


# Should work for both friendly and unfriendly cards
func calculate_buffs():
#	print("calculate called on ", card_data["name"], " in ", get_parent().get_parent().name)

	var friendly = get_parent().get_parent().name == "PlayerSlots"
	var sIdx = slot_idx()
	
	# Reset attack before buff calculation
	attack = card_data["attack"]

	# Edaxio
	if card_data["name"] == "Moon Shard":
		var moon = not (fightManager.get_node("MoonFight/BothMoons/FriendlyMoon").visible if friendly else fightManager.get_node("MoonFight/BothMoons/EnemyMoon").visible)
		
		if friendly:
			for i in range(4):
				if slotManager.is_slot_empty(slotManager.playerSlots[i]) or slotManager.get_friendly_card(i).card_data.name != "Moon Shard":
					moon = false
		else:
			for i in range(4):
				if slotManager.is_slot_empty(slotManager.enemySlots[i]) or slotManager.get_enemy_card(i).card_data.name != "Moon Shard":
					moon = false
		
		if moon:
			fightManager.moon_cutscene(friendly)
			
	# Gem animator
	if "Mox" in card_data["name"]:
		for _ga in slotManager.get_friendly_cards_sigil("Gem Animator") if friendly else slotManager.get_enemy_cards_sigil("Gem Animator"):
			attack += 1
	
	# Green Mage
	if "atkspecial" in card_data:
		match card_data.atkspecial:
			0.0:
				attack = 0
				for mx in slotManager.all_friendly_cards() if friendly else slotManager.all_enemy_cards():
					if "Mox" in mx.card_data["name"]:
						attack += 1
			1.0:
				if friendly:
					if slotManager.get_enemy_card(sIdx):
						attack = slotManager.get_enemy_card(sIdx).attack
				else:
					if slotManager.get_friendly_card(sIdx):
						attack = slotManager.get_friendly_card(sIdx).attack
			2.0:
				attack = card_data.attack
				for ant in slotManager.all_friendly_cards() if friendly else slotManager.all_enemy_cards():
					if "Ant" in ant.card_data["name"] and "ant_limit" in CardInfo.all_data and attack < CardInfo.all_data.ant_limit:
						attack += 1
		
	# Bell Tentacle
	if card_data["name"] == "Bell Tentacle":
		attack = 4 - sIdx
	
	# Hand Tentacle
	if card_data["name"] == "Hand Tentacle":
		var hName = "PlayerHand" if friendly else "EnemyHand"
		attack = fightManager.get_node("HandsContainer/Hands/" + hName).get_child_count()

	# Conduits
	var cfx = slotManager.get_conduitfx(self)

	# Buff Conduit
	attack += cfx.count("Attack Conduit")
	
	# Energy Conduit
	if has_sigil("Energy Conduit"):
		if friendly:
			if fightManager.max_energy_buff == 0:
				for pCard in slotManager.all_friendly_cards():
					if pCard != self and "conduit" in pCard.card_data:
						fightManager.max_energy_buff = 3
						fightManager.set_max_energy(fightManager.max_energy)
						fightManager.set_energy(fightManager.energy + fightManager.max_energy_buff)
						break
			else:
				var found = false
				for pCard in slotManager.all_friendly_cards():
					if pCard != self and "conduit" in pCard.card_data:
						found = true
						break
				if not found:
					fightManager.max_energy_buff = 0
					fightManager.set_max_energy(fightManager.max_energy)
					fightManager.set_energy(min(fightManager.energy, fightManager.max_energy))
		elif fightManager.opponent_max_energy_buff == 0:
			for eCard in slotManager.all_enemy_cards():
				if eCard != self and "conduit" in eCard.card_data:
					fightManager.opponent_max_energy_buff = 2
					fightManager.set_opponent_max_energy(fightManager.opponent_max_energy)
					fightManager.set_opponent_energy(fightManager.opponent_energy + fightManager.opponent_max_energy_buff)
					break
		else:
			var found = false
			for eCard in slotManager.all_enemy_cards():
				if eCard != self and "conduit" in eCard.card_data:
					found = true
					break
				if not found:
					fightManager.opponent_max_energy_buff = 0
					fightManager.set_opponent_max_energy(fightManager.opponent_max_energy)
					fightManager.set_opponent_energy(min(fightManager.opponent_energy, fightManager.opponent_max_energy))

	# Stinky
	if friendly:
		if slotManager.get_enemy_card(sIdx):
			var eCard = slotManager.get_enemy_card(sIdx)
			if eCard.has_sigil("Stinky") and not has_sigil("Made of Stone"):
				attack = max(0, attack - 1)
	else:
		if slotManager.get_friendly_card(sIdx):
			var pCard = slotManager.get_friendly_card(sIdx)
			if pCard.has_sigil("Stinky") and not has_sigil("Made of Stone"):
				attack = max(0, attack - 1)
	
	var sigName = "Leader"
	for c in slotManager.all_friendly_cards() if friendly else slotManager.all_enemy_cards():
		if abs(c.slot_idx() - sIdx) == 1 and c.has_sigil(sigName):
			attack += 1
		
	
	draw_stats()

# New helper funcs
func slot_idx():
	return get_parent().get_position_in_parent()

func has_sigil(sigName):
	if not "sigils" in card_data:
		return false
	else:
		if sigName in card_data["sigils"]:
			return true

# Take damage and die if needed
func take_damage(enemyCard, dmg_amt = -1):

	if $CardBody/HighlightHolder.visible:
		$CardBody/HighlightHolder.visible = false
		return

	if enemyCard and dmg_amt == -1:
		dmg_amt = enemyCard.attack

	health -= dmg_amt
	draw_stats()

	if health <= 0 or (enemyCard and enemyCard.has_sigil("Touch of Death") and not has_sigil("Made of Stone")):
		$AnimationPlayer.play("Perish")
	
	# Sharp quills
	if enemyCard and enemyCard.is_alive() and has_sigil("Sharp Quills"):
		enemyCard.take_damage(self, 1)

func is_alive():
	return not "Perish" in $AnimationPlayer.current_animation and not is_queued_for_deletion()
