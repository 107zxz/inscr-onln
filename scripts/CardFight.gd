extends Control

# Vanguard

onready var sqIdx = CardInfo.idx_from_name("Squirrel")
onready var skIdx = CardInfo.idx_from_name("Skeleton")
onready var geIdx = CardInfo.idx_from_name("Geck")
onready var gsIdx = CardInfo.idx_from_name("Acid Squirrel")
onready var scIdx = CardInfo.idx_from_name("Shambling Cairn")
onready var magIdx = CardInfo.idx_from_name("Magnus Mox")


# Side decks
onready var side_decks = [
	[sqIdx, sqIdx, sqIdx, sqIdx, sqIdx, sqIdx, sqIdx, sqIdx, sqIdx, sqIdx],
	[skIdx, skIdx, skIdx, skIdx, skIdx, skIdx, skIdx, skIdx, skIdx, skIdx],
	[],
	[],
	[],
	[geIdx, geIdx, geIdx],
	[gsIdx],
	[scIdx, scIdx, scIdx, scIdx, scIdx, scIdx, scIdx, scIdx, scIdx, scIdx],
	[magIdx, magIdx]
]

const side_deck_names = [
	"Squirrels",
	"Skeletons",
	"Vessels",
	"Fuck",
	"Fuck",
	"Gecks",
	"GSquirrel",
	"Cairns",
	"Magnus Mox"
]

# Carryovers from lobby
var opponent = -100
var initial_deck = []
var side_deck_index = null

# Settings TBI
var gameSettings = {
	"startingBones": 0
}

# Game components
onready var handManager = $HandsContainer/Hands
onready var playerSlots = $CardSlots/PlayerSlots
onready var enemySlots = $CardSlots/EnemySlots
onready var slotManager = $CardSlots
var cardPrefab = preload("res://packed/playingCard.tscn")

# Game state
enum GameStates {
	DRAWPILE,
	NORMAL,
	SACRIFICE,
	FORCEPLAY,
	BATTLE,
	HAMMER,
}
var state = GameStates.NORMAL

# Health
var advantage = 0
var lives = 2
var opponent_lives = 2
var damage_stun = false

# Resources
var bones = 0
var opponent_bones = 0

var energy = 0
var max_energy = 0
var max_energy_buff = 0
var opponent_energy = 0
var opponent_max_energy = 0
var opponent_max_energy_buff = 0

# Decks
var deck = []
var side_deck = []

# Persistent card state
var turns_starving = 0
var gold_sarcophagus = null

# Network match state
var want_rematch = false

func init_match(opp_id: int):
	opponent = opp_id
	
	# Hide rematch UI
	$WinScreen.visible = false
	want_rematch = false
	$WinScreen/Panel/VBoxContainer/HBoxContainer/RematchBtn.text = "Rematch (0/2)"
	
	# Reset deck
	deck = initial_deck.duplicate()
	deck.shuffle()
	$DrawPiles/YourDecks/Deck.visible = true
	$DrawPiles/YourDecks/SideDeck.visible = true
	$DrawPiles/Notify.visible = false
	
	# Side deck
	if typeof(side_deck_index) == TYPE_ARRAY:
		side_deck = side_deck_index.duplicate()
		$DrawPiles/YourDecks/SideDeck.text = "Mox"
	else:
		# Vessels
		if side_deck_index == 2:
			while side_deck.size() < 10:
				side_deck.append(side_deck[0])
		else:
			# Non-vessels
			side_deck = side_decks[side_deck_index].duplicate()

		$DrawPiles/YourDecks/SideDeck.text = side_deck_names[side_deck_index]
	side_deck.shuffle()
	
	# Reset game state
	advantage = 0
	lives = 2
	opponent_lives = 2
	damage_stun = false
	turns_starving = 0

	# Reset ouro
	var ouro = CardInfo.from_name("Ouroboros")
	ouro["attack"] = 1
	ouro["health"] = 1

	var edax = CardInfo.from_name("Edaxio's Vessel")
	edax["energy_cost"] = 7
	
	$LeftSideUI/AdvantageLabel.text = "Advantage: 0"
	$LeftSideUI/LivesLabel.text = "Lives: 2"
	$LeftSideUI/OpponentLivesLabel.text = "Opponent Lives: 2"
	
	bones = 0
	opponent_bones = 0
	add_bones(gameSettings.startingBones)
	add_opponent_bones(gameSettings.startingBones)
	
	max_energy_buff = 0
	opponent_max_energy_buff = 0
	set_max_energy(int(get_tree().is_network_server()))
	set_energy(max_energy)
	set_opponent_max_energy(int(not get_tree().is_network_server()))
	set_opponent_energy(opponent_max_energy)
	
	state = GameStates.NORMAL
	
	# Clean up hands and field
	handManager.clear_hands()
	slotManager.clear_slots()
		
	# Draw starting hands (sidedeck first for starve check)
	draw_card(side_deck.pop_front(), $DrawPiles/YourDecks/SideDeck)
	if side_deck.size() == 0:
		$DrawPiles/YourDecks/SideDeck.visible = false

	for _i in range(3):
		draw_card(deck.pop_front())
		
		# Some interaction here if your deck has less than 3 cards. Punish by giving opponent starvation
		if deck.size() == 0:
			$DrawPiles/YourDecks/Deck.visible = false
			starve_check()
			break
		
	
	
	$WaitingBlocker.visible = not get_tree().is_network_server()


# Gameplay functions
## LOCAL
func end_turn():
	if not state in [GameStates.NORMAL, GameStates.SACRIFICE]:
		return
	
	# Lower all cards
	handManager.lower_all_cards()
	
	# Remove sacrifice effect from all cards
	slotManager.clear_sacrifices()
	
	# Initiate combat first
	state = GameStates.BATTLE
	
	slotManager.initiate_combat()
	yield(slotManager, "complete_combat")
	
	$WaitingBlocker.visible = true
	damage_stun = false
	
	# Handle sigils
	slotManager.post_turn_sigils()
	yield(slotManager, "resolve_sigils")
		
	# Bump opponent's energy
	if opponent_max_energy < 6:
		set_opponent_max_energy(opponent_max_energy + 1)
	set_opponent_energy(opponent_max_energy)
	
	rpc_id(opponent, "start_turn")

func draw_maindeck():
	if state == GameStates.DRAWPILE:
		
		var next_card = deck.pop_front()

		draw_card(next_card)
		
		state = GameStates.NORMAL
		$DrawPiles/Notify.visible = false
		
		if deck.size() == 0:
			$DrawPiles/YourDecks/Deck.visible = false
		
		starve_check()

func draw_sidedeck():
	if state == GameStates.DRAWPILE:
		draw_card(side_deck.pop_front(), $DrawPiles/YourDecks/SideDeck)
		state = GameStates.NORMAL
		$DrawPiles/Notify.visible = false
		
		if side_deck.size() == 0:
			$DrawPiles/YourDecks/SideDeck.visible = false
		
		starve_check()
		
func search_deck():
	if deck.size() == 0:
		return
	
	$DeckSearch/Panel/VBoxContainer/OptionButton.clear()

	$DeckSearch/Panel/VBoxContainer/OptionButton.add_item("- Select a Card -")
	$DeckSearch/Panel/VBoxContainer/OptionButton.set_item_disabled(0, true)

	for card in deck:
		$DeckSearch/Panel/VBoxContainer/OptionButton.add_item(CardInfo.from_name("name"))

	$DeckSearch.visible = true

func search_callback(index):

	draw_card(deck.pop_at(index - 1))

	if deck.size() == 0:
		$DrawPiles/YourDecks/Deck.visible = false

	starve_check()

	deck.shuffle()

	$DeckSearch.visible = false

func starve_check():
	if deck.size() == 0 and side_deck.size() == 0:
		turns_starving += 1
		
		# Give opponent a starvation
		rpc_id(opponent, "force_draw_starv", turns_starving)
		return true
	return false

func draw_card(card, source = $DrawPiles/YourDecks/Deck):
	var nCard = cardPrefab.instance()
	if typeof(card) == TYPE_DICTIONARY:
		nCard.from_data(card)
	elif typeof(card) == TYPE_STRING:
		nCard.from_data(CardInfo.from_name(card))
	else:
		nCard.from_data(CardInfo.all_cards[card])
	
	source.add_child(nCard)
	
	nCard.rect_position = Vector2.ZERO
	
	# Animate the card
	nCard.move_to_parent(handManager.get_node("PlayerHand"))
	
	rpc_id(opponent, "_opponent_drew_card", str(source.get_path()).split("YourDecks")[1])
	
	# Update deck size
	var dst = "err"
	if source.name == "Deck":
		dst = str(len(deck)) + "/" + str(len(initial_deck))
	else:
		if typeof(side_deck_index) == TYPE_ARRAY:
			dst = str(len(side_deck)) + "/10"
		else:
			dst = str(len(side_deck)) + "/" + str(len(side_decks[side_deck_index]))
	
	source.get_node("SizeLabel").text = dst

	# Hand tenta
	for card in slotManager.all_friendly_cards():
		card.calculate_buffs()

	return nCard

func play_card(slot):
	
	# Is a card ready to be played?
	if handManager.raisedCard:

		var playedCard = handManager.raisedCard
		
		# Only allow playing cards in the NORMAL or FORCEPLAY states
		if state in [GameStates.NORMAL, GameStates.FORCEPLAY]:
			rpc_id(opponent, "_opponent_played_card", playedCard.card_data, slot.get_position_in_parent())
			
			# Bone cost
			if "bone_cost" in playedCard.card_data:
				add_bones(-playedCard.card_data["bone_cost"])
			
			# Energy cost
			if "energy_cost" in playedCard.card_data:
				set_energy(energy -playedCard.card_data["energy_cost"])
			
			playedCard.move_to_parent(slot)
			handManager.raisedCard = null
			state = GameStates.NORMAL
			
			card_summoned(playedCard)

func card_summoned(playedCard):
	# Enable active
	playedCard.get_node("CardBody/VBoxContainer/HBoxContainer/ActiveSigil").mouse_filter = MOUSE_FILTER_STOP
	
	# SIGILS
	if playedCard.has_sigil("Fecundity"):
		var old_data = playedCard.card_data.duplicate()

		old_data.erase("sigils")

		draw_card(old_data)

	if playedCard.has_sigil("Rabbit Hole"):
		draw_card(CardInfo.from_name("Rabbit"))
	if playedCard.has_sigil("Battery Bearer"):
		if max_energy < 6:
			set_max_energy(max_energy + 1)
		set_energy(min(max_energy + max_energy_buff, energy + 1))
	if playedCard.has_sigil("Handy"):
		var cIdx = 0
		for card in handManager.get_node("PlayerHand").get_children():
			if card == playedCard:
				continue
			card.get_node("AnimationPlayer").play("Discard")
			rpc_id(opponent, "_opponent_hand_animation", cIdx, "Discard")
			cIdx += 1
		
		for _i in range(3):
			if deck.size() == 0:
				break
			
			draw_card(deck.pop_front())
			
			# Some interaction here if your deck has less than 3 cards. Don't punish I guess?
			if deck.size() == 0:
				$DrawPiles/YourDecks/Deck.visible = false
				break
			
		draw_card(side_deck.pop_front(), $DrawPiles/YourDecks/SideDeck)
	if playedCard.has_sigil("Mental Gemnastics"):
		for card in slotManager.all_friendly_cards():
			if "Mox" in card.card_data["name"]:
				if deck.size() == 0:
					break
					
				draw_card(deck.pop_front())
		
				# Some interaction here if your deck has less than 3 cards. Don't punish I guess?
				if deck.size() == 0:
					$DrawPiles/YourDecks/Deck.visible = false
					break
	
	# Hoarder
	if playedCard.has_sigil("Hoarder"):
		search_deck()
	
	# Mrs Bomb (wacky one)
	if playedCard.has_sigil("Bomb Spewer"):
		for cSlot in range(4):
			if slotManager.playerSlots[cSlot].get_child_count() > 0 or slotManager.playerSlots[cSlot] == playedCard.get_parent():
				continue

			slotManager.summon_card(CardInfo.from_name("Explode Bot"), cSlot)
			slotManager.rpc_id(opponent, "remote_card_summon", CardInfo.from_name("Explode Bot"), cSlot)

	# Calculate buffs
	for card in slotManager.all_friendly_cards():
		card.calculate_buffs()
	for eCard in slotManager.all_enemy_cards():
		eCard.calculate_buffs()

	# Starvation, inflict damage if 9th onwards
	if playedCard.card_data["name"] == "Starvation" and playedCard.attack >= 9:
		# Ramp damage over time so the game actually ends
		inflict_damage(playedCard.attack - 8)
	
	# Die if gem dependant
	if playedCard.has_sigil("Gem Dependant") and not "Perish" in playedCard.get_node("AnimationPlayer").current_animation:

		var kill = not (slotManager.get_friendly_cards_sigil("Great Mox"))

		for moxcol in ["Green", "Blue", "Orange"]:
			for foundMox in slotManager.get_friendly_cards_sigil(moxcol + " Mox"):
				if foundMox != self:
					kill = false;
					break
		
		if kill:
			print("Gem dependant card should die!")
			playedCard.get_node("AnimationPlayer").play("Perish")
			slotManager.rpc_id(opponent, "remote_card_anim", playedCard.get_parent().get_position_in_parent(), "Perish")
	
	# Edaxio
	if playedCard.card_data["name"] == "Edaxio's Vessel":
		playedCard.card_data["energy_cost"] -= 1
		reload_hand()

		# Check for wincon
		if playedCard.card_data["energy_cost"] < 4:
			$WinScreen/Panel/VBoxContainer/WinLabel.text = "You Win!"
			$WinScreen.visible = true

	# Stoat easter egg
	if playedCard.card_data["name"] == "Stoat":
		playedCard.card_data["name"] = "Total Misplay"
		playedCard.get_node("CardBody/VBoxContainer/Label").text = "Total Misplay"

# Hammer Time
func hammer_mode():
	# Use inverted values for button value, as this happens before its state is toggled
	# Janky hack m8
	
	if slotManager.get_hammerable_cards() == 0 and state == GameStates.NORMAL:
		$LeftSideUI/HammerButton.pressed = true
		return
	
	if state == GameStates.NORMAL:
		state = GameStates.HAMMER
	elif state == GameStates.HAMMER:
		state = GameStates.NORMAL
	
	if state == GameStates.HAMMER:
		$LeftSideUI/HammerButton.pressed = false
	else:
		$LeftSideUI/HammerButton.pressed = true

## REMOTE
remote func _opponent_hand_animation(index, animation):
	handManager.get_node("EnemyHand").get_child(index).get_node("AnimationPlayer").play(animation)

remote func _opponent_drew_card(source_path):
	var nCard = cardPrefab.instance()
	get_node("DrawPiles/EnemyDecks/" + source_path).add_child(nCard)
	nCard.move_to_parent(handManager.get_node("EnemyHand"))
	
	# Hand tenta
	for eCard in slotManager.all_enemy_cards():
		eCard.calculate_buffs()

remote func _opponent_played_card(card, slot):
	
	var card_dt = card if typeof(card) == TYPE_DICTIONARY else CardInfo.all_cards[card]
	
	# Special case: Starvation
	if card_dt["name"] == "Starvation":
		
		# Inflict starve damage
		if turns_starving >= 9:
			inflict_damage(-turns_starving + 8)
	
	handManager.opponentRaisedCard.from_data(card_dt)
	handManager.opponentRaisedCard.move_to_parent(enemySlots.get_child(slot))
	
	# Costs
	if "bone_cost" in card_dt:
		add_opponent_bones(-card_dt["bone_cost"])
	if "energy_cost" in card_dt:
		set_opponent_energy(opponent_energy -card_dt["energy_cost"])
	
	# Guardian
	if slotManager.playerSlots[slot].get_child_count() == 0:
		var guardians = slotManager.get_friendly_cards_sigil("Guardian")
		if guardians:
			slotManager.rpc_id(opponent, "remote_card_move", guardians[0].get_parent().get_position_in_parent(), slot, false)
			guardians[0].move_to_parent(slotManager.playerSlots[slot])
	
	# Buff handling
	for card in slotManager.all_friendly_cards():
		card.calculate_buffs()
	for eCard in slotManager.all_enemy_cards():
		eCard.calculate_buffs()

	if not "sigils" in card_dt:
		return

	# Energy Cell Sigil
	if "Battery Bearer" in card_dt["sigils"]:
		if opponent_max_energy < 6:
			set_opponent_max_energy(opponent_max_energy + 1)
		set_opponent_energy(min(opponent_energy + 1, opponent_max_energy))

	# Mrs Bomb (wacky one)
	if "Bomb Spewer" in card_dt["sigils"]:
		for cSlot in range(4):
			if slotManager.playerSlots[cSlot].get_child_count() > 0:
				continue

			slotManager.summon_card(CardInfo.from_name("Explode Bot"), cSlot)
			slotManager.rpc_id(opponent, "remote_card_summon", CardInfo.from_name("Explode Bot"), cSlot)
	
	# Check for wincon
	if card_dt["name"] == "Edaxio's Vessel" and card_dt["energy_cost"] <= 4:
		$WinScreen/Panel/VBoxContainer/WinLabel.text = "You Win!"
		$WinScreen.visible = true
	
	
## SPECIAL CARD STUFF
remote func force_draw_starv(strength):
	var starv_card = draw_card(0)
	
	var starv_data = CardInfo.all_cards[0]
	starv_data["attack"] = strength
	if strength >= 5:
		starv_data["sigils"].append("Mighty Leap")
	
	starv_card.from_data(starv_data)

# Called during attack animation
func inflict_damage(dmg):
	if damage_stun:
		return
	
	advantage += dmg
	
	if advantage >= 5:
		opponent_lives -= 1
		advantage = 0
		damage_stun = true
	
	if advantage <= -5:
		lives -= 1
		advantage = 0
		damage_stun = true
		
	$LeftSideUI/OpponentLivesLabel.text = "Opponent Lives: " + str(opponent_lives)
	$LeftSideUI/LivesLabel.text = "Lives: " + str(lives)
	$LeftSideUI/AdvantageLabel.text = "Advantage: " + str(advantage)
	
	# Win condition
	if lives == 0:
		$WinScreen/Panel/VBoxContainer/WinLabel.text = "You Lose!"
		$WinScreen.visible = true
	
	if opponent_lives == 0:
		$WinScreen/Panel/VBoxContainer/WinLabel.text = "You Win!"
		$WinScreen.visible = true


# Resource visualisation and management
func add_bones(bone_no):
	bones += bone_no
	$LeftSideUI/BonesLabel.text = "Bones: " + str(bones)

func add_opponent_bones(bone_no):
	opponent_bones += bone_no
	$LeftSideUI/OpponentBonesLabel.text = "Opponent Bones: " + str(opponent_bones)

func set_energy(ener_no):
	energy = ener_no
	$LeftSideUI/EnergyLabel.text = "Energy: " + str(energy)
	
func set_opponent_energy(ener_no):
	opponent_energy = ener_no
	$LeftSideUI/OpponentEnergyLabel.text = "Opponent Energy: " + str(opponent_energy)

func set_max_energy(ener_no):
	max_energy = ener_no
	$LeftSideUI/MaxEnergyLabel.text = "Max Energy: " + str(max_energy + max_energy_buff)
	
func set_opponent_max_energy(ener_no):
	opponent_max_energy = ener_no
	$LeftSideUI/OpponentMaxEnergyLabel.text = "Opponent Max Energy: " + str(opponent_max_energy + opponent_max_energy_buff)

func reload_hand():
	for card in handManager.get_node("PlayerHand").get_children():
		card.from_data(card.card_data)

# Network interactions
## LOCAL
func request_rematch():
	want_rematch = true
	rpc_id(opponent, "_rematch_requested")
	$WinScreen/Panel/VBoxContainer/HBoxContainer/RematchBtn.text = "Rematch (1/2)"

func surrender():
	$WinScreen/Panel/VBoxContainer/WinLabel.text = "You Surrendered!"
	$WinScreen.visible = true
	
	rpc_id(opponent, "_opponent_surrendered")

func quit_match():
	# Tell opponent I surrendered
	rpc_id(opponent, "_opponent_quit")
	
	# Force a disconnect if I'm server
	if get_tree().is_network_server():
		get_tree().network_peer.disconnect_peer(opponent)
	else:
		get_tree().network_peer = null
		visible = false

## REMOTE
remote func _opponent_quit():
	# Quit network
	get_tree().network_peer = null
	visible = false

remote func _opponent_surrendered():
	# Force the game to end
	$WinScreen/Panel/VBoxContainer/WinLabel.text = "Your opponent Surrendered!"
	$WinScreen.visible = true

remote func _rematch_requested():
	if want_rematch:
		rpc_id(opponent, "_rematch_occurs")
		
		init_match(opponent)
	else:
		$WinScreen/Panel/VBoxContainer/HBoxContainer/RematchBtn.text = "Rematch (1/2)"	

remote func _rematch_occurs():
	init_match(opponent)

remote func start_turn():
	damage_stun = false
	$WaitingBlocker.visible = false
	
	# Gold sarcophagus
	if gold_sarcophagus:
		draw_card(gold_sarcophagus)
		gold_sarcophagus = null

	# Resolve start-of-turn effects
	slotManager.pre_turn_sigils()
	yield (slotManager, "resolve_sigils")
	
	# Draw yer cards, if you have any (move this to after effect resolution)
	if starve_check():
		state = GameStates.NORMAL
	else:
		state = GameStates.DRAWPILE
		$DrawPiles/Notify.visible = true
	
	# Increment energy
	if max_energy < 6:
		set_max_energy(max_energy + 1)
	set_energy(max_energy + max_energy_buff)

# This is bad practice but needed for Bone Digger
remote func add_remote_bones(bone_no):
	add_opponent_bones(bone_no)

# Connect in-game signals
func _ready():
	for slot in playerSlots.get_children():
		slot.connect("pressed", self, "play_card", [slot])
