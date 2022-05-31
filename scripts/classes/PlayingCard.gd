extends Control

onready var deckContainer = get_node("/root/Main/DeckEdit/HBoxContainer/VBoxContainer/MainArea/VBoxContainer/DeckPreview/DeckContainer")
onready var previewCont = get_node("/root/Main/DeckEdit/HBoxContainer/CardPreview/PreviewContainer/")

onready var sigilDescPrefab = preload("res://packed/SigilDescription.tscn")
onready var allCardData = get_node("/root/Main/AllCards")
onready var fightManager = get_node("/root/Main/CardFight")
onready var slotManager = get_node("/root/Main/CardFight/CardSlots")

# State
var card_data = {}
var in_hand = true

# Stats
var health = -1
var attack = -1

# Sigil-specific information (must be stored per-card)
var strike_offset = 0 # Used for tri strike, stores which slot the card should attack relative to itself
var sprint_left = false # Used for sprinter

func from_data(cdat):
	card_data = cdat
	
	$CardBody/VBoxContainer/Label.text = card_data.name
	$CardBody/VBoxContainer/Portrait.texture = load("res://gfx/pixport/" + card_data.name + ".png")
	
	# Update card costs and sigils
	draw_cost()
	draw_sigils()
	
	# Set stats
	attack = card_data["attack"]
	health = card_data["health"]
	draw_stats()
	
	# Enable interaction with the card
	$CardBody/Button.disabled = false


func draw_cost():
	if card_data["blood_cost"] > 0:
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BloodCost.visible = true
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BloodCost.texture = $CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BloodCost.texture.duplicate()
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BloodCost.texture.region = Rect2(
			28,
			16 * (card_data["blood_cost"] - 1) + 1,
			26,
			15
		)
	else:
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BloodCost.visible = false
	
	if card_data["bone_cost"] > 0:
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BoneCost.visible = true
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BoneCost.texture = $CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BoneCost.texture.duplicate()
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BoneCost.texture.region = Rect2(
			1,
			16 * (card_data["bone_cost"] - 1) + 1,
			26,
			15
		)
		# Special case: horseman
		if card_data["bone_cost"] == 13:
			$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BoneCost.texture.region = Rect2(
				28,
				145,
				26,
				15
			)
	else:
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BoneCost.visible = false
		
	if card_data["energy_cost"] > 0:
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/EnergyCost.visible = true
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/EnergyCost.texture = $CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/EnergyCost.texture.duplicate()
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/EnergyCost.texture.region = Rect2(
			82,
			16 * (card_data["energy_cost"] - 1) + 1,
			26,
			15
		)
	else:
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/EnergyCost.visible = false
	
	# Mox cost BS
	if card_data["mox_cost"]:
		# Decide which mox to show
		var true_mox = 0
		
		var gmox = "Green" in card_data["mox_cost"]
		var omox = "Orange" in card_data["mox_cost"]
		var bmox = "Blue" in card_data["mox_cost"]
		
		true_mox = moxIdx(gmox, omox, bmox)
		
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/MoxCost.visible = true
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/MoxCost.texture = $CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/MoxCost.texture.duplicate()
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/MoxCost.texture.region = Rect2(
			55,
			16 * true_mox + 1,
			26,
			15
		)
	else:
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/MoxCost.visible = false

func draw_sigils():
	# Sigils
	if len(card_data.sigils) > 0:
		$CardBody/VBoxContainer/HBoxContainer/Sigil.texture = load("res://gfx/sigils/" + card_data.sigils[0] + ".png")
		$CardBody/VBoxContainer/HBoxContainer/Sigil.visible = true
		if len(card_data.sigils) > 1:
			$CardBody/VBoxContainer/HBoxContainer/Sigil2.visible = true
			$CardBody/VBoxContainer/HBoxContainer/Spacer3.visible = true
			$CardBody/VBoxContainer/HBoxContainer/Sigil2.texture = load("res://gfx/sigils/" + card_data.sigils[1] + ".png")
		else:
			$CardBody/VBoxContainer/HBoxContainer/Sigil2.texture = null
			$CardBody/VBoxContainer/HBoxContainer/Sigil2.visible = false
			$CardBody/VBoxContainer/HBoxContainer/Spacer3.visible = false
	else:
		$CardBody/VBoxContainer/HBoxContainer/Sigil.texture = null
		$CardBody/VBoxContainer/HBoxContainer/Sigil2.texture = null
		$CardBody/VBoxContainer/HBoxContainer/Sigil2.visible = false
		$CardBody/VBoxContainer/HBoxContainer/Spacer3.visible = false
		
# Garb
func moxIdx(gmox, omox, bmox) -> int:
	if gmox and omox and bmox:
		return 6
	if gmox and omox:
		return 5
	if omox and bmox:
		return 4
	if bmox and gmox:
		return 3
	if bmox:
		return 2
	if omox: 
		return 1
	if gmox:
		return 0
	return -1

func draw_stats():
	$CardBody/HBoxContainer/AtkScore.text = str(attack)
	$CardBody/HBoxContainer/HpScore.text = str(health)

# When card is clicked
func _on_Button_pressed():
	# Only allow raising while in hand
	if in_hand:
		# Disable hand interactions while in a non-interactable phase
		if not fightManager.state in [fightManager.GameStates.NORMAL, fightManager.GameStates.SACRIFICE]:
			return
		
		if self == get_parent().get_parent().raisedCard:
			lower()
			get_parent().get_parent().raisedCard = null
		elif in_hand:
			
			# Only raise if all costs are met
			if fightManager.bones < card_data["bone_cost"]:
				print("You need more bones!")
				return
				
			if fightManager.energy < card_data["energy_cost"]:
				print("You need more energy!")
				return
			
			if slotManager.get_available_blood() < card_data["blood_cost"]:
				print("You need more sacrifices!")
				return
			
			if card_data["mox_cost"] and not slotManager.get_friendly_cards_sigil("Great Mox"):
				for mox in card_data["mox_cost"]:
					if not slotManager.get_friendly_cards_sigil(mox + " Mox"):
						print(mox + " Mox missing")
						return
			
			# Check if we're cat bricked
			if slotManager.is_cat_bricked():
				return
			
			# Enter sacrifice mode if card needs sacs
			if card_data["blood_cost"] > 0:
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
		if fightManager.state == fightManager.GameStates.HAMMER and get_parent().get_parent().name == "PlayerSlots":
			$AnimationPlayer.play("Perish")
			slotManager.rpc_id(fightManager.opponent, "remote_card_anim", get_parent().get_position_in_parent(), "Perish")
			
			# This card is still dying, so this is eq to an empty board
			if slotManager.get_available_slots() == 3:
				fightManager.hammer_mode()
				# Jank workaround
				fightManager.get_node("LeftSideUI/HammerButton").pressed = false
		
		# Am I about to be sacrificed
		if fightManager.state == fightManager.GameStates.SACRIFICE:
			if self in slotManager.sacVictims:
				slotManager.sacVictims.erase(self)
				$CardBody/SacOlay.visible = false
			else:
				# Make sure we're not about to catbrick
				var brick = true
				
				if slotManager.get_available_slots() == 0 and "Many Lives" in card_data["sigils"]:
					for vic in slotManager.sacVictims:
						if not "Many Lives" in vic.card_data["sigils"]:
							brick = false
							break
				else:
					brick = false
				
				if brick:
					return
				
				# Don't allow sacrificing "Mox" cards
				if "Mox" in card_data["name"]:
					return
				
				slotManager.sacVictims.append(self)
				$CardBody/SacOlay.visible = true
				
				# Attempt a sacrifice
				slotManager.attempt_sacrifice()
				
			slotManager.rpc_id(fightManager.opponent, "set_sac_olay_vis", get_parent().get_position_in_parent(), $CardBody/SacOlay.visible)

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
	# Get card out of hand if possible, and ensure it is not considered raised
	if new_parent.name != "PlayerHand":
		in_hand = false
	
	# Lower cards if just played by active player
	if get_parent().name == "PlayerHand":
		get_parent().get_parent().lower_all_cards()
	
	# Reset position, as expected to be raised when this happens
	$AnimationPlayer.play("RESET")
	
	var gPos = rect_global_position
	get_parent().remove_child(self)
	new_parent.add_child(self)
	
	rect_position = Vector2.ZERO
	$CardBody.rect_global_position = gPos
	
	$Tween.interpolate_property($CardBody, "rect_position", $CardBody.rect_position, Vector2.ZERO, 0.1, Tween.TRANS_LINEAR)
	$Tween.start()


# This is called when the attack animation would "hit". tell the slot manager to make it happen
func attack_hit():
	slotManager.handle_attack(get_parent().get_position_in_parent(), get_parent().get_position_in_parent() + strike_offset)

# Called when the card starts dying. Add bones and stuff
func begin_perish():

	if get_parent().get_parent().name == "PlayerSlots":
		if "Bone King" in card_data["sigils"]:
			fightManager.add_bones(4)
		else:
			fightManager.add_bones(1)

		## SIGILS
		# Ruby Heart
		if "Ruby Heart" in card_data["sigils"]:
			slotManager.summon_card(allCardData.all_cards[98], get_parent().get_position_in_parent())
			slotManager.rpc_id(fightManager.opponent, "remote_card_summon", allCardData.all_cards[98], get_parent().get_position_in_parent())

		# Frozen Away
		if "Frozen Away" in card_data["sigils"]:
			slotManager.summon_card(allCardData.all_cards[78], get_parent().get_position_in_parent())
			slotManager.rpc_id(fightManager.opponent, "remote_card_summon", allCardData.all_cards[78], get_parent().get_position_in_parent())

		# Unkillable
		if "Unkillable" in card_data["sigils"]:
			
			if card_data["name"] == "Ouroboros":
				fightManager.my_ouro_power += 1
				fightManager.rpc_id(fightManager.opponent, "opponent_levelled_ouro")
				
				# Force level all ouros in hand
				for card in get_node("/root/Main/CardFight/HandsContainer/Hands/PlayerHand").get_children():
					if card.card_data["name"] == "Ouroboros":
						card.card_data["attack"] = fightManager.my_ouro_power
						card.card_data["health"] = fightManager.my_ouro_power
						card.from_data(card_data)

			fightManager.draw_card(allCardData.all_cards.find(card_data))
		
		# Gem Animator
		if "Gem Animator" in card_data["sigils"]:
			for slot in slotManager.playerSlots:
				if slot.get_child_count() > 0:
					if "Mox" in slot.get_child(0).card_data["name"]:
						slot.get_child(0).attack -= 1
						slot.get_child(0).draw_stats()
						slotManager.rpc_id(fightManager.opponent, "remote_card_stats", slot.get_position_in_parent(), slot.get_child(0).attack, null)

		# Gem dependent (not this card)
		for sigil in card_data["sigils"]:
			if "Mox" in sigil:

				print("Mox card died! Checking Gem dependant")

				# Any Mox dying tests gem dependant
				var kill = not (slotManager.get_friendly_cards_sigil("Great Mox"))

				for moxcol in ["Green", "Blue", "Orange"]:
					for foundMox in slotManager.get_friendly_cards_sigil(moxcol + " Mox"):
						if foundMox != self:
							kill = false;
							break
				
				if kill:
					print("Gem dependant card should die!")
					var gDep = slotManager.get_friendly_cards_sigil("Gem Dependant")
					if gDep:
						gDep.get_node("AnimationPlayer").play("Perish")
						slotManager.rpc_id(fightManager.opponent, "remote_card_anim", gDep.get_parent().get_position_in_parent(), "Perish")
			break


	else:
		if "Bone King" in card_data["sigils"]:
			fightManager.add_opponent_bones(4)
		else:
			fightManager.add_opponent_bones(1)
	
	# Be on top when I die. This is good for summon-on-death effects
	get_parent().move_child(self, 1)


# This is called when a card evolves with the fledgeling sigil
func evolve():
	from_data(allCardData.all_cards[card_data["evolution"]])
