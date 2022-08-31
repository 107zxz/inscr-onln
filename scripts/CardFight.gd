extends Control

# Vanguard

# Side decks
onready var side_decks = [
	["Squirrel", "Squirrel", "Squirrel", "Squirrel", "Squirrel", "Squirrel", "Squirrel", "Squirrel", "Squirrel", "Squirrel"],
	["Skeleton", "Skeleton", "Skeleton", "Skeleton", "Skeleton", "Skeleton", "Skeleton", "Skeleton", "Skeleton", "Skeleton"],
	[-1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
	[],
	[],
	["Geck", "Geck", "Geck"],
	["Acid Squirrel"],
	["Shambling Cairn", "Shambling Cairn", "Shambling Cairn", "Shambling Cairn", "Shambling Cairn", "Shambling Cairn", "Shambling Cairn", "Shambling Cairn", "Shambling Cairn", "Shambling Cairn"],
	["Moon Shard", "Moon Shard", "Moon Shard", "Moon Shard", "Moon Shard", "Moon Shard", "Moon Shard", "Moon Shard", "Moon Shard", "Moon Shard"]
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
	"Moon Shards"
]



# Carryovers from lobby
var opponent = -100
var initial_deck = []
var side_deck_index = null
var go_first = null

# Game components
onready var handManager = $HandsContainer/Hands
onready var playerSlots = $CardSlots/PlayerSlots
onready var enemySlots = $CardSlots/EnemySlots
onready var slotManager = $CardSlots
var cardPrefab = preload("res://packed/playingCard.tscn")

# Replay
var replay = null

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

var hammers_left = -1

# Decks
var deck = []
var side_deck = []

# Persistent card state
var turns_starving = 0
var gold_sarcophagus = null
var sarcophagus_counter = 0

# Network match state
var want_rematch = false

# Connect in-game signals
func _ready():
	for slot in playerSlots.get_children():
		slot.connect("pressed", self, "play_card", [slot])
	
	$CustomBg.texture = CardInfo.background_texture
	
func init_match(opp_id: int, do_go_first: bool):
	print("Starting match...")
	
	
	opponent = opp_id
	go_first = do_go_first
	
	# Hide rematch UI
	$WinScreen.visible = false
	want_rematch = false
	$WinScreen/Panel/VBoxContainer/HBoxContainer/RematchBtn.text = "Rematch (0/2)"
	
	# Clean up hands and field
	handManager.clear_hands()
	slotManager.clear_slots()

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

	gold_sarcophagus = null
	sarcophagus_counter = 0

	# Hammers
	$LeftSideUI/HammerButton.visible = true
	$LeftSideUI/HammerButton.disabled = false

	if "hammers_per_turn" in CardInfo.all_data:
		hammers_left = CardInfo.all_data.hammers_per_turn

		$LeftSideUI/HammerButton.text = "Hammer (%d/%d)" % [hammers_left, CardInfo.all_data.hammers_per_turn]

		if hammers_left == 0:
			$LeftSideUI/HammerButton.visible = false
			

	# Remove and reset moon
	$MoonFight/AnimationPlayer.play("RESET")

	$PlayerInfo/MyInfo/Candle.set_lives(2)
	$PlayerInfo/TheirInfo/Candle.set_lives(2)
	
	bones = 0
	opponent_bones = 0
	add_bones(0)
	add_opponent_bones(0)
	
	if "starting_bones" in CardInfo.all_data:
		add_bones(CardInfo.all_data.starting_bones)
		add_opponent_bones(CardInfo.all_data.starting_bones)
	
	max_energy_buff = 0
	opponent_max_energy_buff = 0
	set_max_energy(int(go_first))
	set_opponent_max_energy(int(not go_first))
	
	if "starting_energy_max" in CardInfo.all_data:
		set_max_energy(CardInfo.all_data.starting_energy_max)
		set_opponent_max_energy(CardInfo.all_data.starting_energy_max)
	
	set_energy(max_energy)
	set_opponent_energy(opponent_max_energy)
	
	# Start replay
	# TODO: Change names
	replay = Replay.new()
	replay.start($PlayerInfo/MyInfo/Username.text, $PlayerInfo/TheirInfo/Username.text)
	
	state = GameStates.NORMAL
	
	# Draw starting hands (sidedeck first for starve check)
	
	var next_card = side_deck.pop_front()
	
	draw_card(next_card, $DrawPiles/YourDecks/SideDeck)
	
	replay.record_action({"type": "draw_side", "card": next_card})
	
	if side_deck.size() == 0:
		$DrawPiles/YourDecks/SideDeck.visible = false

	for _i in range(3):

		next_card = deck.pop_front()

		draw_card(next_card)

		replay.record_action({"type": "draw_main", "card": next_card})
		
		# Some interaction here if your deck has less than 3 cards. Punish by giving opponent starvation
		if deck.size() == 0:
			$DrawPiles/YourDecks/Deck.visible = false
			starve_check()
			break
		
	$WaitingBlocker.visible = not go_first


# Gameplay functions
## LOCAL
func end_turn():
	if not state in [GameStates.NORMAL, GameStates.SACRIFICE]:
		return
		
	# End turn in replay
	replay.end_turn()
	
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

		# Replay
		replay.record_action({"type": "draw_main", "card": next_card})

		draw_card(next_card)
		
		state = GameStates.NORMAL
		$DrawPiles/Notify.visible = false
		
		if deck.size() == 0:
			$DrawPiles/YourDecks/Deck.visible = false
		
		starve_check()

func draw_sidedeck():
	if state == GameStates.DRAWPILE:
		var next_card = side_deck.pop_front()

		draw_card(next_card, $DrawPiles/YourDecks/SideDeck)

		# Replay
		replay.record_action({"type": "draw_side", "card": next_card})

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
		$DeckSearch/Panel/VBoxContainer/OptionButton.add_item(card)

	$DeckSearch.visible = true

func search_callback(index):

	var targetCard = deck.pop_at(index - 1)

	# Replay
	replay.record_action({"type": "search_deck", "card": targetCard})

	draw_card(targetCard)

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

		# Special: Increase strength of opponent's moon
		if $MoonFight/BothMoons/EnemyMoon.visible:
			$MoonFight/BothMoons/EnemyMoon.attack += 1
			$MoonFight/BothMoons/EnemyMoon.update_stats()

		return true
	return false

func draw_card(card, source = $DrawPiles/YourDecks/Deck):
	
	print("Local player drew card ", card)
	
	var nCard = cardPrefab.instance()
	if typeof(card) == TYPE_DICTIONARY:
		nCard.from_data(card)
	elif typeof(card) == TYPE_STRING:
		nCard.from_data(CardInfo.from_name(card))
	else:
		nCard.from_data(CardInfo.all_cards[card])
	
	source.add_child(nCard)
	
	nCard.rect_position = Vector2.ZERO
	
	var pHand = handManager.get_node("PlayerHand")
	
	# Count cards in their hand
	var nC = 0
	for card in pHand.get_children():
		if not card.is_queued_for_deletion():
			nC += 1
	
	pHand.add_constant_override("separation", - nC * 4)
	
	# Animate the card
	nCard.move_to_parent(pHand)
	
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

			replay.record_action({"type": "summoned_card", "card": playedCard.card_data, "slot": slot.get_position_in_parent()})

			rpc_id(opponent, "_opponent_played_card", playedCard.card_data, slot.get_position_in_parent())
			
			# Bone cost
			if "bone_cost" in playedCard.card_data:
				add_bones(-playedCard.card_data["bone_cost"])
			
			# Energy cost
			if "energy_cost" in playedCard.card_data:
				set_energy(energy -playedCard.card_data["energy_cost"])
			
			playedCard.move_to_parent(slot)
			handManager.raisedCard = null

			# Visual hand update
			var pHand = handManager.get_node("PlayerHand")
			pHand.add_constant_override("separation", - pHand.get_child_count() * 4)

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
	if playedCard.has_sigil("Ant Spawner"):
		draw_card(CardInfo.from_name("Worker Ant"))
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
			if not slotManager.is_slot_empty(slotManager.playerSlots[cSlot]) or slotManager.playerSlots[cSlot] == playedCard.get_parent():
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
	
	# Stoat easter egg
	if playedCard.card_data["name"] == "Stoat":
		playedCard.card_data["name"] = "Total Misplay"
		playedCard.get_node("CardBody/VBoxContainer/Label").text = "Total Misplay"
	
	if playedCard.has_sigil("Armored"):
		playedCard.get_node("CardBody/HighlightHolder").visible = true

# Hammer Time
func hammer_mode():

	replay.record_action({"action": "hammer_mode"})

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

func count_win():
	get_node("/root/Main/TitleScreen").count_victory()

func count_loss():
	get_node("/root/Main/TitleScreen").count_loss(opponent)

## REMOTE
remote func _opponent_hand_animation(index, animation):
	handManager.get_node("EnemyHand").get_child(index).get_node("AnimationPlayer").play(animation)

	if animation == "Raise":
		replay.record_action({"type": "opponent_raised_card", "index": index})
	else:
		replay.record_action({"type": "opponent_lowered_card", "index": index})

remote func _opponent_drew_card(source_path):
	
	print("Opponent drew card!")
	
	# Replay doesn't need to know why opponent drew
	replay.record_action({"type": "opponent_drew_card"})
	
	var nCard = cardPrefab.instance()
	get_node("DrawPiles/EnemyDecks/" + source_path).add_child(nCard)

	# Visual hand update
	var eHand = handManager.get_node("EnemyHand")

	nCard.move_to_parent(eHand)
	
	# Hand tenta
	for eCard in slotManager.all_enemy_cards():
		eCard.calculate_buffs()
	
	# Count cards in their hand
	var nC = 0
	for card in eHand.get_children():
		if not card.is_queued_for_deletion():
			nC += 1
	
	eHand.add_constant_override("separation", - nC * 4)


remote func _opponent_played_card(card, slot):
	
	# Replay
	replay.record_action({"type": "opponent_summoned_card", "card": card, "slot": slot})
	
	var card_dt = card if typeof(card) == TYPE_DICTIONARY else CardInfo.all_cards[card]
	
	# Special case: Starvation
	if card_dt["name"] == "Starvation":
		
		# Inflict starve damage
		if turns_starving >= 9:
			inflict_damage(-turns_starving + 8)
	
	handManager.opponentRaisedCard.from_data(card_dt)
	handManager.opponentRaisedCard.move_to_parent(enemySlots.get_child(slot))

	# Visual hand update
	var eHand = handManager.get_node("EnemyHand")
	eHand.add_constant_override("separation", - eHand.get_child_count() * 4)
	
	# Costs
	if "bone_cost" in card_dt:
		add_opponent_bones(-card_dt["bone_cost"])
	if "energy_cost" in card_dt:
		set_opponent_energy(opponent_energy -card_dt["energy_cost"])
	
	# Guardian
	if slotManager.is_slot_empty(slotManager.playerSlots[slot]):
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
			if not slotManager.is_slot_empty(slotManager.playerSlots[cSlot]):
				continue

			slotManager.summon_card(CardInfo.from_name("Explode Bot"), cSlot)
			slotManager.rpc_id(opponent, "remote_card_summon", CardInfo.from_name("Explode Bot"), cSlot)
	
	if "Armored" in card_dt.sigils:
		slotManager.enemySlots[slot].get_child(0).get_node("CardBody/HighlightHolder").visible = true

	
	
## SPECIAL CARD STUFF
remote func force_draw_starv(strength):

	# Moon
	if $MoonFight/BothMoons/FriendlyMoon.visible:
		$MoonFight/BothMoons/FriendlyMoon.attack += 1
		$MoonFight/BothMoons/FriendlyMoon.update_stats()

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
		
	$Advantage/AdvLeft/PickLeft.rect_position.x = 104 + advantage * 20
	$Advantage/AdvRight/PickRight.rect_position.x = 104 + advantage * 20
	
	$PlayerInfo/MyInfo/Candle.set_lives(lives)
	$PlayerInfo/TheirInfo/Candle.set_lives(opponent_lives)
	
	# Win condition
	if lives == 0:
		$WinScreen/Panel/VBoxContainer/WinLabel.text = "You Lose!"

		# Moon special
		if $MoonFight/BothMoons/EnemyMoon.visible:
			$WinScreen/Panel/VBoxContainer/WinLabel.text = "You Lose via Coup de Lune!"

		$WinScreen.visible = true
		get_node("/root/Main/TitleScreen").count_loss(opponent)
	
	if opponent_lives == 0:
		$WinScreen/Panel/VBoxContainer/WinLabel.text = "You Win!"

		# Moon special
		if $MoonFight/BothMoons/FriendlyMoon.visible:
			$WinScreen/Panel/VBoxContainer/WinLabel.text = "You Win via Coup de Lune!"

		$WinScreen.visible = true
		get_node("/root/Main/TitleScreen").count_victory()
		

# Resource visualisation and management
func add_bones(bone_no):
	bones += bone_no
	$PlayerInfo/MyInfo/Bones/BoneCount.text = str(bones)
	$PlayerInfo/MyInfo/Bones/BoneCount2.text = str(bones)

func add_opponent_bones(bone_no):
	opponent_bones += bone_no
	$PlayerInfo/TheirInfo/Bones/BoneCount.text = str(bones)
	$PlayerInfo/TheirInfo/Bones/BoneCount2.text = str(bones)

func set_energy(ener_no):
	energy = ener_no
	$PlayerInfo/MyInfo/Energy/AvailableEnergy.rect_size.x = 10 * ener_no
	
func set_opponent_energy(ener_no):
	opponent_energy = ener_no
	$PlayerInfo/TheirInfo/Energy/AvailableEnergy.rect_size.x = 10 * ener_no
	$PlayerInfo/TheirInfo/Energy/AvailableEnergy.rect_position.x = 20 - 20 * ener_no

func set_max_energy(ener_no):
	max_energy = ener_no
	$PlayerInfo/MyInfo/Energy/MaxEnergy.rect_size.x = 10 * ener_no
	
func set_opponent_max_energy(ener_no):
	opponent_max_energy = ener_no
	$PlayerInfo/TheirInfo/Energy/MaxEnergy.rect_size.x = 10 * ener_no
	$PlayerInfo/TheirInfo/Energy/MaxEnergy.rect_position.x = 20 - 20 * ener_no


func reload_hand():
	for card in handManager.get_node("PlayerHand").get_children():
		card.from_data(card.card_data)


# CUTSCENES
func moon_cutscene(friendly: bool):
	
	if friendly:
		$MoonFight/AnimationPlayer.play("friendlyMoon")
	else:
		$MoonFight/AnimationPlayer.play("enemyMoon")

	if GameOptions.enable_moon_music:
		$MoonFight/AudioStreamPlayer.play()

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
	
	# Document Result
	get_node("/root/Main/TitleScreen").count_loss(opponent)

func quit_match():
	# Tell opponent I surrendered
	rpc_id(opponent, "_opponent_quit")
	
	visible = false
	$MoonFight/AnimationPlayer.play("RESET")
	get_node("/root/Main/TitleScreen").update_lobby()
	
	debug_cleanup()

## REMOTE
remote func _opponent_quit():
	# Quit network
	visible = false
	$MoonFight/AnimationPlayer.play("RESET")
	get_node("/root/Main/TitleScreen").update_lobby()
	
	debug_cleanup()
	

remote func _opponent_surrendered():
	# Force the game to end
	$WinScreen/Panel/VBoxContainer/WinLabel.text = "Your opponent Surrendered!"
	$WinScreen.visible = true
	
	# Document Result
	get_node("/root/Main/TitleScreen").count_victory()

func debug_cleanup():
	# Quit if I'm a debug instance
	if "autoquit" in OS.get_cmdline_args():
		get_tree().quit()
	
	if "DEBUG_HOST" in get_node("PlayerInfo/MyInfo/Username").text:
		get_node("/root/Main/TitleScreen")._on_LobbyQuit_pressed()
	else:
		print("\"%s\"" % get_node("PlayerInfo/MyInfo/Username").text)

remote func _rematch_requested():
	if want_rematch:
		rpc_id(opponent, "_rematch_occurs")
		
		init_match(opponent, not go_first)
	else:
		$WinScreen/Panel/VBoxContainer/HBoxContainer/RematchBtn.text = "Rematch (1/2)"	

remote func _rematch_occurs():
	init_match(opponent, not go_first)

remote func start_turn():
	damage_stun = false
	$WaitingBlocker.visible = false
	
	# Update Replay
	replay.start_turn()
	
	# Gold sarcophagus
	if gold_sarcophagus:
		if sarcophagus_counter <= 0:
			draw_card(gold_sarcophagus)
			gold_sarcophagus = null
			sarcophagus_counter = 0
		else:
			sarcophagus_counter -= 1
	
	# Hammers
	if "hammers_per_turn" in CardInfo.all_data:
		hammers_left = CardInfo.all_data.hammers_per_turn
		$LeftSideUI/HammerButton.text = "Hammer (%d/%d)" % [hammers_left, CardInfo.all_data.hammers_per_turn]
	
	$LeftSideUI/HammerButton.disabled = false

	# Resolve start-of-turn effects
	slotManager.pre_turn_sigils()
	yield (slotManager, "resolve_sigils")
	
	# Increment energy
	if max_energy < 6:
		set_max_energy(max_energy + 1)
	set_energy(max_energy + max_energy_buff)

	if $MoonFight/BothMoons/FriendlyMoon.visible:
		# Special moon logic
		state = GameStates.NORMAL
		end_turn()
		pass
	else:
		# Draw yer cards, if you have any (move this to after effect resolution)
		if starve_check():
			state = GameStates.NORMAL
		else:
			state = GameStates.DRAWPILE
			$DrawPiles/Notify.visible = true
	
	

# This is bad practice but needed for Bone Digger
remote func add_remote_bones(bone_no):
	add_opponent_bones(bone_no)

