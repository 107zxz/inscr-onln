extends Control

onready var deckContainer = get_node("/root/Main/DeckEdit/HBoxContainer/VBoxContainer/MainArea/VBoxContainer/DeckPreview/DeckContainer")
onready var previewCont = get_node("/root/Main/DeckEdit/HBoxContainer/CardPreview/PreviewContainer/")

onready var sigilDescPrefab = preload("res://packed/SigilDescription.tscn")
onready var fightManager = get_node("/root/Main/CardFight")
onready var slotManager = get_node("/root/Main/CardFight/CardSlots")

onready var cardAudio = fightManager.get_node("CardSFX")

var paperTheme = preload("res://themes/papertheme.tres")

# You asked for it
const sfx = {
	"blood": preload("res://sfx/pixel_card_attack_nature.wav"),
	"energy": preload("res://sfx/pixel_card_attack_tech.wav"),
	"bone": preload("res://sfx/pixel_card_attack_undead.wav"),
	"mox": preload("res://sfx/pixel_card_attack_wizard.wav"),
	"death": preload("res://sfx/pixel_card_death.wav"),
	"sac": preload("res://sfx/pixel_card_sacrifice.wav"),
}

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
var consider_dead = false

func from_data(cdat):
	card_data = cdat.duplicate()

	$CardBody.draw_from_data(card_data)

	# Set stats
	attack = card_data["attack"]
	health = card_data["health"]
	draw_stats()

	# Enable interaction with the card
	$CardBody/CardBtn.disabled = false

	create_sigils("Player" in get_path() as String or "Your" in get_path() as String)

func load_vanilla_sigil(name: String):
	var sigPath = "res://scripts/classes/sigils/" + name + ".gd"
	if ResourceLoader.exists(sigPath):
		return load(sigPath).new()
	else:
		return false

func load_custom_sigil(name: String):
	var sigPath = CardInfo.scripts_path + CardInfo.ruleset + "_" + name + ".gd"
	var d = Directory.new()
	if d.file_exists(sigPath):
		return load(sigPath).new()
	else:
		return false

func create_sigils(friendly):
	sigils.clear()

	if not "sigils" in card_data:
		return

	for sig in card_data.sigils:
		
		var ns = load_custom_sigil(sig)
		
		if not ns:
			ns = load_vanilla_sigil(sig)
		
		if not ns:
			print("Sigil '%s' not found!" % sig)
			continue
		
		ns.fightManager = fightManager
		ns.slotManager = slotManager
		ns.card = self
		ns.isFriendly = friendly
		sigils.append(ns)

func handle_sigil_event(event, params):
	for sig in sigils:
		sig.handle_event(event, params)

func draw_stats():
	$CardBody/AtkScore.text = str(attack)
	$CardBody/HpScore.text = str(health)

# When card is clicked
func _on_Button_pressed():

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

		# Am I being picked for a snipe?
		if fightManager.state == fightManager.GameStates.SNIPE and self != fightManager.sniper and get_parent().get_parent().name in ["PlayerSlots", "EnemySlots"]:

			if not fightManager.snipe_is_attack or get_parent().get_parent().name == "EnemySlots":
				# Inform opponent of sniping (this could be fucky with latency)
				fightManager.send_move({
					"type": "snipe_target",
					"from_slot": fightManager.sniper.slot_idx(),
					"to_slot": slot_idx(),
					"friendly": get_parent().get_parent().name == "PlayerSlots"
				})

				# Do the snipe
				fightManager.emit_signal("snipe_complete", get_parent().get_parent().name == "PlayerSlots", slot_idx())
#				fightManager.state = fightManager.GameStates.BATTLE


		# Is it hammer time? Am I on the player's side?
		if fightManager.state == fightManager.GameStates.HAMMER and get_parent().get_parent().name in ["PlayerSlots", "PlayerSlotsBack"] and not "nohammer" in card_data:
			$AnimationPlayer.play("Perish")
#			slotManager.rpc_id(fightManager.opponent, "remote_card_anim", get_parent().get_position_in_parent(), "Perish")
			fightManager.send_move({
				"type": "card_anim",
				"index": slot_idx(),
				"anim": "Perish"
			})

			# Always turn off hammer after hammering something (requested)
			fightManager.hammer_mode()
			# Jank workaround
			fightManager.get_node("LeftSideUI/HammerButton").pressed = false

			if "hammers_per_turn" in CardInfo.all_data and CardInfo.all_data.hammers_per_turn != -1:
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
				if not get_parent().get_parent().name in ["PlayerSlots", "PlayerSlotsBack"]:
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
	if self != get_parent().get_parent().raisedCard:
		get_parent().get_parent().lower_all_cards()
		get_parent().get_parent().raisedCard = self

		$AnimationPlayer.play("Raise")

		# Show the opponent the card was raised
		fightManager.send_move(
			{
				"type": "raise_card",
				"index": get_position_in_parent()
			}
		)

	# get_parent().get_parent().rpc_id(fightManager.opponent, "raise_opponent_card", get_position_in_parent())

func lower():
	if self == get_parent().get_parent().raisedCard:
		$AnimationPlayer.play("Lower")

		# Show the opponent the card was lowered
		fightManager.send_move(
			{
				"type": "lower_card",
				"index": get_position_in_parent()
			}
		)

#		get_parent().get_parent().rpc_id(fightManager.opponent, "lower_opponent_card", get_position_in_parent())

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
#		fightManager.emit_signal("sigil_event", "card_summoned", [self])

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



	yield($Tween, "tween_completed")


	# Fuck you godot
	$CardBody.modulate = $CardBody.HVR_COLOURS[0]

	# Must be summoned
	if new_parent.get_parent().name in ["PlayerSlots", "EnemySlots"]:
		if from_hand:
#			fightManager.emit_signal("sigil_event", "card_summoned", [self])
			fightManager.card_summoned(self)

			# Special atk stats
			if "atkspecial" in card_data:
				$CardBody/AtkIcon.visible = false
				$CardBody/AtkScore.visible = true

		else:
			fightManager.emit_signal("sigil_event", "card_moved", [self, get_parent().get_position_in_parent(), new_parent.get_position_in_parent()])


# This is called when the attack animation would "hit". tell the slot manager to make it happen
func attack_hit():
	if get_parent().get_parent().name == "PlayerSlots":
		slotManager.handle_attack(slot_idx(), slot_idx() + strike_offset)
	else:
		slotManager.handle_enemy_attack(slot_idx(), slot_idx() + strike_offset)

# Called when the card starts dying. Add bones and stuff
func begin_perish(doubleDeath = false):

	# For necro
	var canRespawn = true
	fightManager.emit_signal("sigil_event", "card_perished", [self])

	if get_parent().get_parent().name == "PlayerSlots":
		if doubleDeath:
			fightManager.card_summoned(self)
#			fightManager.emit_signal("sigil_event", "card_summoned", [self])
		# Bones
		fightManager.add_bones(1)

		# Remove Energy Conduit Buff
		if has_sigil("Energy Conduit (+3)"):
			print("Removing buff")
			fightManager.max_energy_buff = 0
			fightManager.set_max_energy(fightManager.max_energy)
			fightManager.set_energy(min(fightManager.energy, fightManager.max_energy))
		if has_sigil("Energy Conduit"):
			fightManager.no_energy_deplete = false

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
		if doubleDeath:
			fightManager.card_summoned(self)

		# Bones
		fightManager.add_opponent_bones(1)

		# Energy conduit buff
		if has_sigil("Energy Conduit (+3)"):
			print("Removing enemy buff")
			fightManager.opponent_max_energy_buff = 0
			fightManager.set_opponent_max_energy(fightManager.opponent_max_energy)
			fightManager.set_opponent_energy(min(fightManager.opponent_energy, fightManager.opponent_max_energy))
		if has_sigil("Energy Conduit"):
			fightManager.enemy_no_energy_deplete = false

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

	# Special case: Fledgling 2
	if has_sigil("Fledgling 2"):

		# Deep copy
		var new_sigs: Array = card_data.sigils.duplicate()
		new_sigs.erase("Fledgling 2")
		new_sigs.append("Fledgling")
		card_data.sigils = new_sigs

		from_data(card_data)

		return

	var dmgTaken = card_data["health"] - health

	from_data(CardInfo.from_name(card_data["evolution"]))

	health = card_data["health"] - dmgTaken

	# Calculate buffs
	for card in slotManager.all_friendly_cards():
		card.calculate_buffs()
	for eCard in slotManager.all_enemy_cards():
		eCard.calculate_buffs()

	# Summoned card
#	fightManager.card_summoned(self)


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
		$CardBody/Active.disabled = true
		$CardBody/Active.mouse_filter = MOUSE_FILTER_IGNORE
#		slotManager.rpc_id(fightManager.opponent, "remote_activate_sigil", get_parent().get_position_in_parent(), attack)

		fightManager.send_move({
			"type": "activate_sigil",
			"slot": slot_idx(),
			"arg": attack
		})

		return

	if sName == "Effigy":
		if fightManager.bones < 3:
			return

		# Does not work on the moon
		if fightManager.get_node("MoonFight/BothMoons/EnemyMoon").visible:
			return

		# Anyone to curse?
		if len(slotManager.all_enemy_cards()) == 0:
			return

		# Ready No. 13
		fightManager.sniper = self
		fightManager.state = fightManager.GameStates.SNIPE
		fightManager.snipe_is_attack = false

		var target = yield(fightManager, "snipe_complete")
		fightManager.state = fightManager.GameStates.NORMAL

		var eCard = slotManager.get_enemy_card(target[1])

		# Don't let you shoot nothing
		if not eCard:
			return
			
		# Don't let you apply the sigil more than once
		if "sigils" in eCard.card_data and "Sympathetic Connection" in eCard.card_data.sigils:
			return

		fightManager.add_bones(-3)

		# Add the new sigil to the card
		var new_sigs = []
		
		if "sigils" in eCard.card_data:
			new_sigs = eCard.card_data.sigils.duplicate()
		new_sigs.append("Sympathetic Connection")
		eCard.card_data.sigils = new_sigs
		eCard.from_data(eCard.card_data)

		fightManager.send_move({
			"type": "activate_sigil",
			"slot": slot_idx(),
			"arg": target[1]
		})

		return


	if sName == "Energy Gun":
		if fightManager.energy < 1:
			return

		if slotManager.is_slot_empty(slotManager.enemySlots[get_parent().get_position_in_parent()]) and not fightManager.get_node("MoonFight/BothMoons/EnemyMoon").visible:
			return

		var eCard = slotManager.enemySlots[get_parent().get_position_in_parent()].get_child(0)
		if not fightManager.no_energy_deplete:
			fightManager.set_energy(fightManager.energy - 1)

		if fightManager.get_node("MoonFight/BothMoons/EnemyMoon").visible:
			fightManager.get_node("MoonFight/BothMoons/EnemyMoon").take_damage(1)
		else:
			eCard.take_damage(self, 1)

	if sName == "Energy Sniper":
		if fightManager.energy < 1:
			return

		if not fightManager.no_energy_deplete:
			fightManager.set_energy(fightManager.energy - 1)
		
		if fightManager.get_node("MoonFight/BothMoons/EnemyMoon").visible:

			fightManager.get_node("MoonFight/BothMoons/EnemyMoon").take_damage(1)

			fightManager.send_move({
				"type": "activate_sigil",
				"slot": slot_idx(),
				"arg": 0
			})
			return

		# Anyone to snipe?
		if len(slotManager.all_enemy_cards()) == 0:
			return

		# Ready No. 13
		fightManager.sniper = self
		fightManager.state = fightManager.GameStates.SNIPE
		fightManager.snipe_is_attack = false

		var target = yield(fightManager, "snipe_complete")
		fightManager.state = fightManager.GameStates.NORMAL

		var eCard = slotManager.get_enemy_card(target[1])

		# Don't let you shoot nothing
		if not eCard:
			return


		eCard.take_damage(self, 1)

		fightManager.send_move({
			"type": "activate_sigil",
			"slot": slot_idx(),
			"arg": target[1]
		})

		return

	if sName == "Energy Gun (Eternal)":
		if fightManager.energy < 1:
			return

		if slotManager.is_slot_empty(slotManager.enemySlots[get_parent().get_position_in_parent()]) and not fightManager.get_node("MoonFight/BothMoons/EnemyMoon").visible:
			return

		var eCard = slotManager.enemySlots[get_parent().get_position_in_parent()].get_child(0)

		var dmg = min(fightManager.energy, eCard.health)

		if not fightManager.no_energy_deplete:
			fightManager.set_energy(fightManager.energy - dmg)

		if fightManager.get_node("MoonFight/BothMoons/EnemyMoon").visible:
			fightManager.get_node("MoonFight/BothMoons/EnemyMoon").take_damage(dmg)
		else:
			eCard.take_damage(self, dmg)

	if sName == "Power Dice":
		if fightManager.energy < 1:
			return

		if not fightManager.no_energy_deplete:
			fightManager.set_energy(fightManager.energy - 1)

		attack = randi() % 6 + 1
		card_data["attack"] = attack
		draw_stats()

	if sName == "Power Dice (2)":
		if fightManager.energy < 2:
			return

		if not fightManager.no_energy_deplete:
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

	if sName == "Enlarge (3)":
		if fightManager.bones < 3:
			return

		fightManager.add_bones(-3)
		health += 1
		card_data.attack += 1 # Save attack to avoid deletion later
		attack += 1

		draw_stats()

	if sName == "Stimulate":
		if fightManager.energy < 3:
			return

		if not fightManager.no_energy_deplete:
			fightManager.set_energy(fightManager.energy - 3)
		health += 1
		card_data.attack += 1 # Save attack to avoid deletion later
		attack += 1

		draw_stats()

	if sName == "Stimulate (4)":
		if fightManager.energy < 4:
			return

		if not fightManager.no_energy_deplete:
			fightManager.set_energy(fightManager.energy - 4)
		health += 1
		card_data.attack += 1 # Save attack to avoid deletion later
		attack += 1

		draw_stats()

	if sName == "Bonehorn":
		if fightManager.energy < 1:
			return

		if not fightManager.no_energy_deplete:
			fightManager.set_energy(fightManager.energy - 1)
		fightManager.add_bones(3)
	if sName == "Bonehorn (1)":
		if fightManager.energy < 1:
			return

		if not fightManager.no_energy_deplete:
			fightManager.set_energy(fightManager.energy - 1)
		fightManager.add_bones(1)

	if sName == "Disentomb":
		if fightManager.bones < 1:
			return

		fightManager.add_bones(-1)
		fightManager.draw_card(CardInfo.from_name("Skeleton"))
	if sName == "Disentomb (Corpses)":
		if fightManager.bones < 2:
			return

		fightManager.add_bones(-2)
		fightManager.draw_card(CardInfo.from_name("Withered Corpse"))

	# Disable button until start of next turn
	if CardInfo.all_data.opt_actives:
		$CardBody/Active.disabled = true
		$CardBody/Active.mouse_filter = MOUSE_FILTER_IGNORE
		$CardBody._on_Active_button_up()

	# Play anim and activate remotely
	if not "Perish" in $AnimationPlayer.current_animation:
		$AnimationPlayer.play("ProcGeneric")

	fightManager.send_move({
		"type": "activate_sigil",
		"slot": slot_idx(),
		"arg": attack
	})

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
	if "mox" in card_data["name"].to_lower():
		for _ga in slotManager.get_friendly_cards_sigil("Gem Animator") if friendly else slotManager.get_enemy_cards_sigil("Gem Animator"):
			attack += 1

	# Green Mage
	if "atkspecial" in card_data:
		match card_data.atkspecial:
			"green_mox":
				attack = 0
				for mx in slotManager.all_friendly_cards() if friendly else slotManager.all_enemy_cards():
					if "sigils" in mx.card_data and "Green Mox" in mx.card_data["sigils"]:
						attack += 1
			"mox":
				attack = 0
				for mx in slotManager.all_friendly_cards() if friendly else slotManager.all_enemy_cards():
					if "mox" in mx.card_data["name"].to_lower():
						attack += 1
			"mirror":
				if friendly:
					if slotManager.get_enemy_card(sIdx):
						attack = slotManager.get_enemy_card(sIdx).attack
				else:
					if slotManager.get_friendly_card(sIdx):
						attack = slotManager.get_friendly_card(sIdx).attack
			"ant":
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

	# SPECIAL: Buff conduit buffs all conduits
#	if "conduit" in card_data:
#		for crd in (slotManager.all_friendly_cards() if friendly else slotManager.all_enemy_cards()):
#			if crd.has_sigil("Attack Conduit"):
#				attack += 1
#
	# Energy Conduit
	if has_sigil("Energy Conduit (+3)"):
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
					fightManager.opponent_max_energy_buff = 3
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

	if has_sigil("Energy Conduit"):
		if friendly:
			fightManager.no_energy_deplete = true
		else:
			fightManager.enemy_no_energy_deplete = true

	# Stinky, Annoying
	if friendly:
		if slotManager.get_enemy_card(sIdx):
			var eCard = slotManager.get_enemy_card(sIdx)
			if not has_sigil("Made of Stone"):
				if eCard.has_sigil("Stinky"):
					attack = max(0, attack - 1)
				if eCard.has_sigil("Annoying"):
					attack += 1

	else:
		if slotManager.get_friendly_card(sIdx):
			var pCard = slotManager.get_friendly_card(sIdx)
			if not has_sigil("Made of Stone"):
				if pCard.has_sigil("Stinky"):
					attack = max(0, attack - 1)
				if pCard.has_sigil("Annoying"):
					attack += 1

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

	if $CardBody/Highlight.visible:
		$CardBody/Highlight.visible = false
		return

	if enemyCard and dmg_amt == -1:
		dmg_amt = enemyCard.attack

	health -= dmg_amt
	draw_stats()

	if health <= 0 or (enemyCard and enemyCard.has_sigil("Touch of Death") and not has_sigil("Made of Stone")):
		$AnimationPlayer.play("Perish")

	# Sigils that do the do
	fightManager.emit_signal("sigil_event", "card_hit", [self, enemyCard])

#	if enemyCard and enemyCard.is_alive() and has_sigil("Sharp Quills"):
#		enemyCard.take_damage(self, 1)

func is_alive():
	return not consider_dead and not "Perish" in $AnimationPlayer.current_animation and not is_queued_for_deletion() and health > 0


func play_sfx(name):
	# TODO: Make this play on a global sfx thing (also on a different bus (same with music))
	match name:
		"attack":
			for cost in ["energy", "bone", "mox"]:
				if cost +"_cost" in card_data:
					cardAudio.stream = sfx[cost]
					break
			cardAudio.stream = sfx["blood"]
		"perish":
			cardAudio.stream = sfx["death"]
		"sac":
			cardAudio.stream = sfx["sac"]

	cardAudio.play()
