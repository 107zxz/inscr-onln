extends Control

# Carryovers from lobby
var opponent = -100
var deck = []

# Game components
onready var handManager = $HandsContainer/Hands
onready var playerSlots = $CardSlots/PlayerSlots
onready var enemySlots = $CardSlots/EnemySlots
onready var allCards = get_node("/root/Main/AllCards")
onready var slotManager = $CardSlots
var cardPrefab = preload("res://packed/playingCard.tscn")

# Game state
enum GameStates {
	DRAWPILE,
	NORMAL,
	SACRIFICE,
	FORCEPLAY,
	BATTLE,
	HAMMER
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
var opponent_energy = 0
var opponent_max_energy = 0

# Network match state
var want_rematch = false

func init_match(opp_id: int):
	opponent = opp_id
	
	# Hide rematch UI
	$WinScreen.visible = false
	want_rematch = false
	$WinScreen/Panel/VBoxContainer/HBoxContainer/RematchBtn.text = "Rematch (0/2)"
	
	# Reset game state
	advantage = 0
	lives = 2
	opponent_lives = 2
	damage_stun = false
	
	bones = 0
	opponent_bones = 0
	add_bones(0)
	add_opponent_bones(0)
	
	set_max_energy(int(get_tree().is_network_server()))
	set_energy(max_energy)
	set_opponent_max_energy(int(not get_tree().is_network_server()))
	set_opponent_energy(opponent_max_energy)
	
	state = GameStates.NORMAL
	
	# Clean up hands and field
	handManager.clear_hands()
	slotManager.clear_slots()
		
	# Draw starting hands
	for _i in range(4):
		draw_card(deck[randi() % deck.size()])
	draw_card(29)
	
	$WaitingBlocker.visible = not get_tree().is_network_server()


# Gameplay functions
## LOCAL
func commence_combat():
	if not state in [GameStates.NORMAL, GameStates.SACRIFICE]:
		return
	
	# Lower all cards
	handManager.lower_all_cards()
	
	# Remove sacrifice effect from all cards
	slotManager.clear_sacrifices()
	
	# Initiate combat first
	state = GameStates.BATTLE
	slotManager.initiate_combat()

func draw_maindeck():
	if state == GameStates.DRAWPILE:
		
		draw_card(deck[randi() % deck.size()])
		
		state = GameStates.NORMAL
		$DrawPiles/Notify.visible = false

func draw_sidedeck():
	if state == GameStates.DRAWPILE:
		draw_card(29, $DrawPiles/YourDecks/SideDeck)
		state = GameStates.NORMAL
		$DrawPiles/Notify.visible = false

func draw_card(idx, source = $DrawPiles/YourDecks/Deck):
	var nCard = cardPrefab.instance()
	nCard.from_data(allCards.all_cards[idx])
	source.add_child(nCard)
	
	nCard.rect_position = Vector2.ZERO
	
	# Animate the card
	nCard.move_to_parent(handManager.get_node("PlayerHand"))
	
	rpc_id(opponent, "_opponent_drew_card", str(source.get_path()).split("YourDecks")[1])

func play_card(slot):
	
	# Is a card ready to be played?
	if handManager.raisedCard:
		
		# Only allow playing cards in the NORMAL or FORCEPLAY states
		if state in [GameStates.NORMAL, GameStates.FORCEPLAY]:
			rpc_id(opponent, "_opponent_played_card", allCards.all_cards.find(handManager.raisedCard.card_data), slot.get_position_in_parent())
			
			# Bone cost
			add_bones(-handManager.raisedCard.card_data["bone_cost"])
			
			# Energy cost
			set_energy(energy -handManager.raisedCard.card_data["energy_cost"])
			
			# SIGILS
			for sigil in handManager.raisedCard.card_data["sigils"]:
				if sigil == "Fecundity":
					draw_card(allCards.all_cards.find(handManager.raisedCard.card_data))
				if sigil == "Rabbit Hole":
					draw_card(20)
				if sigil == "Battery Bearer":
					if max_energy < 6:
						set_max_energy(max_energy + 1)
					set_energy(min(max_energy, energy + 1))
			
			handManager.raisedCard.move_to_parent(slot)
			handManager.raisedCard = null
			state = GameStates.NORMAL

## REMOTE
remote func _opponent_drew_card(source_path):
	var nCard = cardPrefab.instance()
	get_node("DrawPiles/EnemyDecks/" + source_path).add_child(nCard)
	nCard.move_to_parent(handManager.get_node("EnemyHand"))

remote func _opponent_played_card(card, slot):
	handManager.opponentRaisedCard.from_data(allCards.all_cards[card])
	handManager.opponentRaisedCard.move_to_parent(enemySlots.get_child(slot))
	
	# Costs
	add_opponent_bones(-allCards.all_cards[card]["bone_cost"])
	set_opponent_energy(opponent_energy -allCards.all_cards[card]["energy_cost"])
	
	# Energy Cell Sigil
	if "Battery Bearer" in allCards.all_cards[card]["sigils"]:
		if opponent_max_energy < 6:
			set_opponent_max_energy(opponent_max_energy + 1)
		set_opponent_energy(min(opponent_energy + 1, opponent_max_energy))

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
	$LeftSideUI/MaxEnergyLabel.text = "Max Energy: " + str(max_energy)
	
func set_opponent_max_energy(ener_no):
	opponent_max_energy = ener_no
	$LeftSideUI/OpponentMaxEnergyLabel.text = "Opponent Max Energy: " + str(opponent_max_energy)


# Network interactions
## LOCAL
func request_rematch():
	want_rematch = true
	rpc_id(opponent, "_rematch_requested")
	$WinScreen/Panel/VBoxContainer/HBoxContainer/RematchBtn.text = "Rematch (1/2)"

func end_turn():
	$WaitingBlocker.visible = true
	damage_stun = false
	
	# Bump opponent's energy
	if opponent_max_energy < 6:
		set_opponent_max_energy(opponent_max_energy + 1)
	set_opponent_energy(opponent_max_energy)
	
	rpc_id(opponent, "start_turn")

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
	
	# Setup card drawing
	state = GameStates.DRAWPILE
	$DrawPiles/Notify.visible = true
	
	# Increment energy
	if max_energy < 6:
		set_max_energy(max_energy + 1)
	set_energy(max_energy)




# Connect in-game signals
func _ready():
	for slot in playerSlots.get_children():
		slot.connect("pressed", self, "play_card", [slot])
