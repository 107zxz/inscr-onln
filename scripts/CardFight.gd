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

func init_match(opp_id: int):
	opponent = opp_id
	
	# Clean up hands
	handManager.clear_hands()
		
	# Draw starting hands
	for _i in range(4):
		draw_card(deck[randi() % deck.size()])
	draw_card(28)
	
	$WaitingBlocker.visible = not get_tree().is_network_server()



	

func surrender():
	# Tell opponent I surrendered
	rpc_id(opponent, "_opponent_surrendered")
	
	# Force a disconnect if I'm server
	if get_tree().is_network_server():
		get_tree().network_peer.disconnect_peer(opponent)
	else:
		get_tree().network_peer = null
		visible = false
	# Quit network
#	get_tree().network_peer = null
#	visible = false

# Gameplay functions
func commence_combat():
	print("Bell hit, ending turn")
	
	# Lower all cards
	handManager.lower_all_cards()
	
	# Remove sacrifice effect from all cards
	slotManager.clear_sacrifices()
	
	# Initiate combat first
	state = GameStates.BATTLE
	slotManager.initiate_combat()

func end_turn():
	$WaitingBlocker.visible = true
	damage_stun = false
	
	rpc_id(opponent, "start_turn")
	

func draw_maindeck():
	if state == GameStates.DRAWPILE:
		
		draw_card(deck[randi() % deck.size()])
		
		state = GameStates.NORMAL
		$DrawPiles/Notify.visible = false

func draw_sidedeck():
	if state == GameStates.DRAWPILE:
		draw_card(28, $DrawPiles/YourDecks/SideDeck)
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

# Called by clicking a slot, also programatically
func playCard(slot):
	
	# Is a card ready to be played?
	if handManager.raisedCard:
		
		# Only allow playing cards in the NORMAL or FORCEPLAY states
		if state in [GameStates.NORMAL, GameStates.FORCEPLAY]:
			rpc_id(opponent, "_opponent_played_card", allCards.all_cards.find(handManager.raisedCard.card_data), slot.get_position_in_parent())
			handManager.raisedCard.move_to_parent(slot)
			handManager.raisedCard = null
			state = GameStates.NORMAL

func inflict_damage(dmg):
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

func request_rematch():
	print("Rematch requested!")

# Remote signals
remote func _opponent_surrendered():
	# Quit network
	get_tree().network_peer = null
	visible = false

remote func _opponent_drew_card(source_path):
	var nCard = cardPrefab.instance()
	get_node("DrawPiles/EnemyDecks/" + source_path).add_child(nCard)
	nCard.move_to_parent(handManager.get_node("EnemyHand"))

remote func _opponent_played_card(card, slot):
	handManager.opponentRaisedCard.from_data(allCards.all_cards[card])
	handManager.opponentRaisedCard.move_to_parent(enemySlots.get_child(slot))

remote func _rematch_requested():
	pass
	
remote func start_turn():
	damage_stun = false
	$WaitingBlocker.visible = false
	
	# Setup card drawing
	state = GameStates.DRAWPILE
	$DrawPiles/Notify.visible = true

# Connect in-game signals
func _ready():
	for slot in playerSlots.get_children():
		slot.connect("pressed", self, "playCard", [slot])

