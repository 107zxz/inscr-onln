extends Control

# Carryovers from lobby
var opponent = -100
var initial_deck = []
var side_deck_key = null
var go_first = null

var spectating = false

# Game components
onready var handManager = $HandsContainer/Hands
onready var slotManager = $CardSlots
var cardPrefab = preload("res://packed/playingCard.tscn")

# Signals
signal sigil_event(event, params)
#signal snipe_complete(card)
signal snipe_complete(friendly, slot)

# Move format:

# X: {
#	id: X <- Redundant but it helps. I should have done this for cards
#	pid: 0 <- Owner of move
#	type: "play_card"
#   [arbitrary params below]
#	card: {} <- card_data
#	slot: 3,
# }

var moves = {}
var current_move = 0
var acting = false

# Game state
enum GameStates {
	DRAWPILE,
	NORMAL,
	SACRIFICE,
	FORCEPLAY,
	BATTLE,
	HAMMER,
	SNIPE
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
var side_deck_cards = []

# Persistent card state
var turns_starving = 0
var gold_sarcophagus = []
var no_energy_deplete = false
var enemy_no_energy_deplete = false

# Temp card state
var sniper: Control = null
var snipe_is_attack = false
var sniper_target: Control = null

# Network match state
var want_rematch = false

# Connect in-game signals
func _ready():
	$CustomBg.texture = CardInfo.background_texture
	
	# Backrow
	if CardInfo.all_data.enable_backrow:
		$CardSlots/EnemySlotsBack.show()
		$CardSlots/PlayerSlotsBack.show()
		for back_slot in slotManager.playerSlotsBack:
			back_slot.connect("pressed", self, "play_card_back", [back_slot])
	else:
		for slot in slotManager.playerSlots:
			slot.connect("pressed", self, "play_card", [slot])
		for eSlot in slotManager.enemySlots:
			eSlot.connect("pressed", self, "clicked_enemy_slot", [eSlot])


func _process(_delta):
	if state == GameStates.SNIPE:
		$SniperLine.visible = true
		if is_instance_valid(sniper):
			$SniperLine.points[0] = sniper.rect_global_position + Vector2(64, 90)
		$SniperLine.points[1] = get_global_mouse_position()
	else:
		$SniperLine.visible = false


func init_match(opp_id: int, do_go_first: bool):
	
	
	opponent = opp_id
	go_first = do_go_first
	
	# Hide rematch UI
	$WinScreen.visible = false
	want_rematch = false
	$WinScreen/Panel/VBoxContainer/HBoxContainer/RematchBtn.text = "Rematch (0/2)"
	
	# Clean up hands and field
	handManager.clear_hands()
	slotManager.clear_slots()
	
	# Stop any ongoing music
	$MusPlayer.stop()

	# Reset deck
	deck = initial_deck.duplicate()
	deck.shuffle()
	$DrawPiles/YourDecks/Deck.visible = true
	$DrawPiles/YourDecks/SideDeck.visible = true
	$DrawPiles/Notify.visible = false
	
	
	
	# TODO: Clean up. This is spaghetti city

	# Side deck new
	if not side_deck_key:
		$DrawPiles/YourDecks/SideDeck.visible = false
		$DrawPiles/EnemyDecks/SideDeck.visible = false
	
	elif side_deck_cards != []:
		side_deck = side_deck_cards.duplicate()
		$DrawPiles/YourDecks/SideDeck.text = side_deck_key
	
	elif typeof(side_deck_key) == TYPE_STRING: # Single
		$DrawPiles/YourDecks/SideDeck.text = side_deck_key
		side_deck = []
		for _i in range(CardInfo.side_decks[side_deck_key].count):
			side_deck.append(CardInfo.side_decks[side_deck_key].card)
	
	else: # Single category
		$DrawPiles/YourDecks/SideDeck.text = " ".join([side_deck_key[1], side_deck_key[0]])
		side_deck = []
		for _i in range(CardInfo.side_decks[side_deck_key[0]].cards[side_deck_key[1]].count):
			side_deck.append(CardInfo.side_decks[side_deck_key[0]].cards[side_deck_key[1]].card)

	# Shuffle side deck after adding cards
	side_deck.shuffle()
	
	# Reset game state
	advantage = 0
	lives = CardInfo.all_data.num_candles
	opponent_lives = CardInfo.all_data.num_candles

	damage_stun = false
	turns_starving = 0

	gold_sarcophagus = []
	no_energy_deplete = false
	enemy_no_energy_deplete = false

	moves = {}
	current_move = 0

	# Hammers
	$LeftSideUI/HammerButton.visible = true
	$LeftSideUI/HammerButton.disabled = false

	if "hammers_per_turn" in CardInfo.all_data and CardInfo.all_data.hammers_per_turn != -1:
		hammers_left = CardInfo.all_data.hammers_per_turn

		$LeftSideUI/HammerButton.text = "Hammer (%d/%d)" % [hammers_left, CardInfo.all_data.hammers_per_turn]

		if hammers_left == 0:
			$LeftSideUI/HammerButton.visible = false
			

	# Remove and reset moon
	$MoonFight/AnimationPlayer.play("RESET")

	$PlayerInfo/MyInfo/Candle.set_lives(lives)
	$PlayerInfo/TheirInfo/Candle.set_lives(opponent_lives)
	
	bones = 0
	opponent_bones = 0
	add_bones(0)
	add_opponent_bones(0)
	
	inflict_damage(0)
	
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
	
	state = GameStates.NORMAL
	
	# Draw starting hands (sidedeck first for starve check)
	
	var next_card = side_deck.pop_front()
	
	# Draw client-side
	if side_deck_key != null:
		draw_card(next_card, $DrawPiles/YourDecks/SideDeck, false)
		_opponent_drew_card("SideDeck")
	
	if side_deck.size() == 0:
		$DrawPiles/YourDecks/SideDeck.visible = false

	for _i in range(3 if side_deck_key != null else 4):

		next_card = deck.pop_front()

		# Draw client-side
		draw_card(next_card, $DrawPiles/YourDecks/Deck, false)
		_opponent_drew_card("Deck")

		# Some interaction here if your deck has less than 3 cards. Punish by giving opponent starvation
		if deck.size() == 0:
			
			$DrawPiles/YourDecks/Deck.visible = false
			starve_check(false)
			break
		
	$WaitingBlocker.visible = not go_first


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
	
	slotManager.initiate_combat(true)
	yield(slotManager, "complete_combat")
	
	# Opponent should handle post-turn sigils and energy
	# At the start of their turn
#	rpc_id(opponent, "start_turn")
	send_move({
		"type": "end_turn"
	})
	
	$WaitingBlocker.visible = true
	damage_stun = false
	
	# Handle sigils
	slotManager.post_turn_sigils(true)
	yield(slotManager, "resolve_sigils")
	
	# Shift cards forwards
	if CardInfo.all_data.enable_backrow:
		slotManager.shift_cards_forward(true)
		
	# Bump opponent's energy
	if opponent_max_energy < 6:
		set_opponent_max_energy(opponent_max_energy + 1)
	set_opponent_energy(opponent_max_energy)
	
	# Pre turn sigils
	slotManager.pre_turn_sigils(false)

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
		var next_card = side_deck.pop_front()

		draw_card(next_card, $DrawPiles/YourDecks/SideDeck)

		state = GameStates.NORMAL
		$DrawPiles/Notify.visible = false
		
		if side_deck.size() == 0:
			$DrawPiles/YourDecks/SideDeck.visible = false
		
		starve_check()
		
func search_deck():
	if deck.size() == 0:
		return
	
	if GameOptions.options.improveSearch:
		# kill all child
		for child in $newSearch/Panel/ScrollContainer/VBoxContainer.get_children():
			$newSearch/Panel/ScrollContainer/VBoxContainer.remove_child(child)
			child.queue_free()
		
		for card in deck:
			var style = load("res://themes/papertheme.tres")
		
			var hBox = HBoxContainer.new()
			
			var labelStyle = StyleBoxFlat.new()
			var label = Button.new()
			
			var pic = TextureRect.new()
			var spacer = Control.new()

			var bgStyle = StyleBoxFlat.new()
			var bg = Panel.new()
			
			var card_data = CardInfo.from_name(card)
			
			# setting color and style
			if "nohammer" in card_data:
				labelStyle.bg_color = style.get_stylebox("nohammer_normal", "Card").bg_color
				bgStyle.bg_color = style.get_stylebox("nohammer_normal", "Card").bg_color
			elif "rare" in card_data and "nosac" in card_data:
				labelStyle.bg_color = style.get_stylebox("rns_normal", "Card").bg_color
				bgStyle.bg_color = style.get_stylebox("rns_normal", "Card").bg_color
			elif "nosac" in card_data:
				labelStyle.bg_color = style.get_stylebox("nosac_normal", "Card").bg_color
				bgStyle.bg_color = style.get_stylebox("nosac_normal", "Card").bg_color
			elif "rare" in card_data:
				labelStyle.bg_color = style.get_stylebox("rare_normal", "Card").bg_color
				bgStyle.bg_color = style.get_stylebox("rare_normal", "Card").bg_color
			else:
				labelStyle.bg_color = style.get_stylebox("normal", "Card").bg_color
				bgStyle.bg_color = style.get_stylebox("normal", "Card").bg_color
				
			# make the button label
			label.text = card
			label.toggle_mode = true
			label.size_flags_horizontal = SIZE_EXPAND_FILL
			
			label.set_script(load("res://scripts/UI/deckListHover.gd"))
			label.connect("pressed", self, "search_callback")
			
			label.add_stylebox_override("normal", labelStyle) # bg 
			label.add_color_override( # font
				"font_color",
				load("res://themes/sigilMat.tres").get_shader_param("u_replacement_color")
			)
			
			# make the pic
			# code rob from DrawCard.gd
			var d = Directory.new()
			if d.file_exists(CardInfo.portrait_override_path + card_data.name + ".png"):
				var i = Image.new()
				i.load(CardInfo.portrait_override_path + card_data.name + ".png")
				var tx = ImageTexture.new()
				tx.create_from_image(i)
				tx.flags -= tx.FLAG_FILTER
				pic.texture = tx
			elif "pixport_url" in card_data:
				var i = Image.new()
				i.load(CardInfo.custom_portrait_path + CardInfo.ruleset + "_" + card_data.name + ".png")
				var tx = ImageTexture.new()
				tx.create_from_image(i)
				tx.flags -= tx.FLAG_FILTER
				pic.texture = tx
			else:
				pic.texture = load("res://gfx/pixport/" + card_data.name + ".png")
				
			pic.material = load("res://themes/sigilMat.tres")
			var scale = 1 # 1 look nicest
			pic.rect_min_size = Vector2(
				pic.texture.get_width() * scale,
				pic.texture.get_height() * scale
			)
			pic.expand = true
			pic.stretch_mode = TextureRect.STRETCH_SCALE_ON_EXPAND
			
			# bg time
			bg.rect_min_size = pic.rect_min_size
			bg.add_stylebox_override("panel", bgStyle)
			
			bg.add_child(pic)
			hBox.add_child(bg)
			
			hBox.add_child(spacer)
			hBox.add_child(label)
			
			for special in ["rare", "nohammer", "nosac"]:
				if special in card_data:
					var texture = TextureRect.new()
					var atlast = AtlasTexture.new()
					atlast.atlas = load("res://gfx/cardextras/SpecialSigils.png")
					atlast.region = (
						Rect2(12,0,13,15) if special == "nosac" 
						else Rect2(12,15,13,15) if special == "rare" 
						else Rect2(12,30,13,15)
					)
					texture.texture = atlast
					texture.rect_min_size = Vector2(
						atlast.region.size.x * 2,
						atlast.region.size.y * 2
					)
					texture.expand = true
					texture.stretch_mode = TextureRect.STRETCH_SCALE_ON_EXPAND
					hBox.add_child(texture)
			
			$newSearch/Panel/ScrollContainer/VBoxContainer.add_child(hBox)
		
		$newSearch.visible = true
	else:
		$DeckSearch/Panel/VBoxContainer/OptionButton.clear()

		$DeckSearch/Panel/VBoxContainer/OptionButton.add_item("- Select a Card -")
		$DeckSearch/Panel/VBoxContainer/OptionButton.set_item_disabled(0, true)

		for card in deck:
			$DeckSearch/Panel/VBoxContainer/OptionButton.add_item(card)

		$DeckSearch.visible = true

func search_callback(index=1):
	if GameOptions.options.improveSearch:
		for i in $newSearch/Panel/ScrollContainer/VBoxContainer.get_children().size():
			if $newSearch/Panel/ScrollContainer/VBoxContainer.get_child(i).get_child(2).pressed:
				index = i + 1
				break
	
	var targetCard = deck.pop_at(index - 1)

	draw_card(targetCard)

	if deck.size() == 0:
		$DrawPiles/YourDecks/Deck.visible = false

	starve_check()

	deck.shuffle()

	$DeckSearch.visible = false
	$newSearch.visible = false

func starve_check(soft_rpc = true):
	if deck.size() == 0 and side_deck.size() == 0:
		turns_starving += 1
		
		# Give opponent a starvation
		if soft_rpc:
			send_move({
				"type": "hey_im_a_hungry",
				"for": turns_starving
			})
		else:
			rpc_id(opponent, "force_draw_starv", turns_starving)
		
		# This doesn't trigger a callback RPC from the opponent, so make them draw
		_opponent_drew_card("Deck")
		
		# Special: Increase strength of opponent's moon
		if $MoonFight/BothMoons/EnemyMoon.visible:
			$MoonFight/BothMoons/EnemyMoon.attack += 1
			$MoonFight/BothMoons/EnemyMoon.update_stats()

		return true
	return false

func draw_card(card, source = $DrawPiles/YourDecks/Deck, do_rpc = true):
	
	
	var nCard = cardPrefab.instance()
	
	source.add_child(nCard)
	
	if typeof(card) == TYPE_DICTIONARY:
		nCard.from_data(card)
	elif typeof(card) == TYPE_STRING:
		nCard.from_data(CardInfo.from_name(card))
	else:
		nCard.from_data(CardInfo.all_cards[card])
	
	# New sigil stuff
	nCard.fightManager = self
	nCard.slotManager = slotManager
#	nCard.create_sigils(true)
	connect("sigil_event", nCard, "handle_sigil_event")
	
	
	nCard.rect_position = Vector2.ZERO
	
	var pHand = handManager.get_node("PlayerHand")
	
	# Count cards in their hand
	var nC = 0
	for card in pHand.get_children():
		if not card.is_queued_for_deletion():
			nC += 1
	
	pHand.add_constant_override("separation", - min(nC, 12) * 4)
	
	# Animate the card
	nCard.move_to_parent(pHand)
	
	if do_rpc:
#		rpc_id(opponent, "_opponent_drew_card", str(source.get_path()).split("YourDecks")[1])
		send_move({
			"type": "draw_card",
			"deck": str(source.get_path()).split("YourDecks")[1]
		})
	
	# Update deck size
	var dst = "err"
	if source.name == "Deck":
		dst = str(len(deck)) + "/" + str(len(initial_deck))
	else:
		if typeof(side_deck_key) == TYPE_STRING:
			dst = str(len(side_deck)) + "/" + str(CardInfo.side_decks[side_deck_key].count)
		else:
			dst = str(len(side_deck)) + "/" + str(CardInfo.side_decks[side_deck_key[0]].cards[side_deck_key[1]].count)
		
	source.get_node("SizeLabel").text = dst

	# Hand tenta
	for card in slotManager.all_friendly_cards():
		card.calculate_buffs()

	return nCard

func play_card(slot: Node):
	
	# Is a card ready to be played?
	if handManager.raisedCard:

		var playedCard = handManager.raisedCard
		
		# Only allow playing cards in the NORMAL or FORCEPLAY states
		if state in [GameStates.NORMAL, GameStates.FORCEPLAY]:
			
			# Dirty override for jukebot
			if playedCard.card_data.name == "Jukebot":
				$MusPicker.visible = true
				yield($MusPicker/Panel/VBoxContainer/DlBtn, "pressed")
				$MusPicker.visible = false
				playedCard.card_data.song = $MusPicker/Panel/VBoxContainer/SongUrl.text

#			rpc_id(opponent, "_opponent_played_card", playedCard.card_data, slot.get_position_in_parent())
			
			send_move({
				"type": "play_card",
				"card": playedCard.card_data,
				"slot": slot.get_position_in_parent()
			})
			
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
			

func play_card_back(slot):
	
	# Is a card ready to be played?
	if handManager.raisedCard:

		var playedCard = handManager.raisedCard
		
		# Only allow playing cards in the NORMAL or FORCEPLAY states
		if state in [GameStates.NORMAL, GameStates.FORCEPLAY]:
			
			# Dirty override for jukebot
			if playedCard.card_data.name == "Jukebot":
				$MusPicker.visible = true
				yield($MusPicker/Panel/VBoxContainer/DlBtn, "pressed")
				$MusPicker.visible = false
				playedCard.card_data.song = $MusPicker/Panel/VBoxContainer/SongUrl.text

#			rpc_id(opponent, "_opponent_played_card", playedCard.card_data, slot.get_position_in_parent())
			
			send_move({
				"type": "play_card_back",
				"card": playedCard.card_data,
				"slot": slot.get_position_in_parent()
			})
			
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
			
			yield(playedCard.get_node("Tween"), "tween_completed")
			
#			card_summoned(playedCard)

func card_summoned(playedCard):
	# Enable active
	if playedCard.get_parent().get_parent().name == "PlayerSlots":
		playedCard.get_node("CardBody/Active").mouse_filter = MOUSE_FILTER_STOP
	
	# Sigil event
	emit_signal("sigil_event", "card_summoned", [playedCard])
	
	# Calculate buffs
	for card in slotManager.all_friendly_cards():
		card.calculate_buffs()
	for eCard in slotManager.all_enemy_cards():
		eCard.calculate_buffs()

	# Starvation, inflict damage if 9th onwards
	if playedCard.card_data["name"] == "Starvation" and playedCard.attack >= 9:
		# Ramp damage over time so the game actually ends
		inflict_damage(playedCard.attack - 8)
	
	# Stoat easter egg (Goodbye)
#	if playedCard.card_data["name"] == "Stoat":
#		playedCard.card_data["name"] = "Total Misplay"
#		playedCard.get_node("CardBody/VBoxContainer/Label").text = "Total Misplay"

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

func count_win():
	get_node("/root/Main/TitleScreen").count_victory()

func count_loss():
	get_node("/root/Main/TitleScreen").count_loss(opponent)


# New unified
func send_move(move):
	move.id = current_move
	move.pid = get_tree().get_network_unique_id()
	
	# Save a copy for replay completeness
	moves[current_move] = move
	
	current_move += 1
	rpc("_player_did_move", move)


## REMOTE

# New unified
remote func _player_did_move(move):
	moves[move.id] = move
	
	if not acting:
		acting = true
		parse_next_move()


func move_done():
	
	print("Move ", current_move - 1, " complete!")
	
	$DesyncWatcher.stop()
	
	if current_move in moves:
		parse_next_move()
	else:
		acting = false

func _on_DesyncWatcher_timeout():
	print("Desync Detected!!!")
	
	$WinScreen/Panel/VBoxContainer/WinLabel.text = "Desync Detected!"
	$WinScreen.visible = true
	
	rpc( "_opponent_detected_desync")
	
func parse_next_move():
	
	$DesyncWatcher.start()
	
	var move = moves[current_move]
	current_move += 1
	
	if move.pid == opponent:
		match move.type:
			"raise_card":
				print("Opponent ", move.pid, " raised card ", move.index)
				handManager.raise_opponent_card(move.index)
			"lower_card":
				print("Opponent ", move.pid, " lowered card ", move.index)
				handManager.lower_opponent_card(move.index)
			"draw_card":
				print("Opponent ", move.pid, " drew card")
				_opponent_drew_card(move.deck)
			"play_card":
				print("Opponent ", move.pid, " played card ", move.card, " in slot ", move.slot)
				_opponent_played_card(move.card, move.slot, move.ignore_cost  if "ignore_cost" in move else false)
			"play_card_back":
				print("Opponent ", move.pid, " played card ", move.card, " in back slot ", move.slot)
				_opponent_played_card_back(move.card, move.slot, move.ignore_cost if "ignore_cost" in move else false)
			"hey_im_a_hungry":
				print("Opponent is like ", move.for, " hungry.")
				force_draw_starv(move.for)
			"save_replay":
				save_replay()
			"end_turn":
				print("Opponent ended turn")
				start_turn()
			"card_anim":
				print("Opponent card ", move.index, " did animation ", move.anim)
				slotManager.remote_card_anim(move.index, move.anim)
			"activate_sigil":
				print("Opponent card ", move.slot, " activated sigil with arg ", move.arg)
				slotManager.remote_activate_sigil(move.slot, move.arg)
			"change_card":
				print("Opponent card ", move.index, " changed to ", move.data)
				slotManager.remote_card_data(move.index, move.data)
			"snipe_target":
				print("Opponent sniped from ", move.from_slot, " to slot ", move.to_slot, " friendly: ", move.friendly)
				# Trigger the signal
				var nt = slotManager.get_enemy_card(move.to_slot) if move.friendly else slotManager.get_friendly_card(move.to_slot)
				sniper_target = nt if nt else null
				emit_signal("snipe_complete", move.friendly, move.to_slot)
				
				move_done()
			"snuff_candle":
				inflict_damage(10)
				damage_stun = false
				move_done()
			_:
				print("Opponent ", move.pid, " did unhandled move:")
				print(move)
	else:
		# Parsing my own moves
		match move.type:
			"raise_card":
				print("You ", move.pid, " raised card ", move.index)
				$HandsContainer/Hands/PlayerHand.get_child(move.index).raise()
				yield($HandsContainer/Hands/PlayerHand.get_child(move.index).get_node("AnimationPlayer"), "animation_finished")
				move_done()
			"lower_card":
				print("You ", move.pid, " lowered card ", move.index)
				$HandsContainer/Hands/PlayerHand.get_child(move.index).lower()
				yield($HandsContainer/Hands/PlayerHand.get_child(move.index).get_node("AnimationPlayer"), "animation_finished")
				move_done()
			"draw_card":
				print("You ", move.pid, " drew card")
				_opponent_drew_card(move.deck)
			"play_card":
				print("You ", move.pid, " played card ", move.card, " in slot ", move.slot)
				var pCard = handManager.raisedCard
				play_card(move.slot)
				yield(pCard.get_node("Tween"), "tween_completed")
				move_done()
			"hey_im_a_hungry":
				print("You're like ", move.for, " hungry.")
				force_draw_starv(move.for)
			"end_turn":
				print("Ended turn")
				start_turn()
			"card_anim":
				print("Friendly card ", move.index, " did animation ", move.anim)
				slotManager.remote_card_anim(move.index, move.anim)
			"activate_sigil":
				print("Friendly card ", move.slot, " activated sigil with arg ", move.arg)
				slotManager.remote_activate_sigil(move.slot, move.arg)
			"change_card":
				print("Friendly card ", move.index, " changed to ", move.data)
				slotManager.remote_card_data(move.index, move.data)
			"snuff_candle":
				inflict_damage(-10)
				draw_card(CardInfo.from_name("Greater Smoke"))
				move_done()
			_:
				print("You did unhandled move:")
				print(move)

func save_replay():
	print("Saving replay: ", moves)

func _opponent_drew_card(source_path):
	
	print("Opponent drew card!")
	
	var nCard = cardPrefab.instance()
	get_node("DrawPiles/EnemyDecks/" + source_path).add_child(nCard)

	nCard.get_node("CardBody").apply_theme({})

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
	
	move_done()
	

func _opponent_played_card(card, slot, ignore_cost = false):
	
	var card_dt = card if typeof(card) == TYPE_DICTIONARY else CardInfo.all_cards[card]
	
	# Special case: Starvation
	if card_dt["name"] == "Starvation":
		
		# Inflict starve damage
		if turns_starving >= 9:
			inflict_damage(-turns_starving + 8)
	
	# Visual hand update
	var eHand = handManager.get_node("EnemyHand")
	eHand.add_constant_override("separation", - min(eHand.get_child_count(), 12) * 4)
	
	# Costs
	if not ignore_cost:
		if "bone_cost" in card_dt:
			add_opponent_bones(-card_dt["bone_cost"])
		if "energy_cost" in card_dt and not no_energy_deplete:
			set_opponent_energy(opponent_energy -card_dt["energy_cost"])
	
	# Sigil effects:
	var nCard = handManager.opponentRaisedCard
	nCard.from_data(card_dt)
#	nCard.create_sigils(false)
	nCard.move_to_parent(slotManager.enemySlots[slot])
	nCard.fightManager = self
	nCard.slotManager = slotManager
	connect("sigil_event", nCard, "handle_sigil_event")
	
	yield(nCard.get_node("Tween"), "tween_completed")
	move_done()
	
#	emit_signal("sigil_event", "card_summoned", [nCard])

	# Special case, card unlikely to have handled event yet
	
	# Buff handling
	for card in slotManager.all_friendly_cards():
		card.calculate_buffs()
	for eCard in slotManager.all_enemy_cards():
		eCard.calculate_buffs()
	
func _opponent_played_card_back(card, slot, ignore_cost = false):
	
	var card_dt = card if typeof(card) == TYPE_DICTIONARY else CardInfo.all_cards[card]
	
	# Special case: Starvation
#	if card_dt["name"] == "Starvation":
#
#		# Inflict starve damage
#		if turns_starving >= 9:
#			inflict_damage(-turns_starving + 8)
	
	# Visual hand update
	var eHand = handManager.get_node("EnemyHand")
	eHand.add_constant_override("separation", - min(eHand.get_child_count(), 12) * 4)
	
	# Costs
	if not ignore_cost:
		if "bone_cost" in card_dt:
			add_opponent_bones(-card_dt["bone_cost"])
		if "energy_cost" in card_dt and not no_energy_deplete:
			set_opponent_energy(opponent_energy -card_dt["energy_cost"])
	
	# Sigil effects:
	var nCard = handManager.opponentRaisedCard
	nCard.from_data(card_dt)
#	nCard.create_sigils(false)
	nCard.move_to_parent(slotManager.enemySlotsBack[slot])
	nCard.fightManager = self
	nCard.slotManager = slotManager
	connect("sigil_event", nCard, "handle_sigil_event")
	
	yield(nCard.get_node("Tween"), "tween_completed")
	move_done()
	
#	emit_signal("sigil_event", "card_summoned", [nCard])

	# Special case, card unlikely to have handled event yet
	
	# Buff handling
#	for card in slotManager.all_friendly_cards():
#		card.calculate_buffs()
#	for eCard in slotManager.all_enemy_cards():
#		eCard.calculate_buffs()
	

## SPECIAL CARD STUFF
remote func force_draw_starv(strength):

	# Moon
	if $MoonFight/BothMoons/FriendlyMoon.visible:
		$MoonFight/BothMoons/FriendlyMoon.attack += 1
		$MoonFight/BothMoons/FriendlyMoon.update_stats()

	var starv_card = draw_card(0, $DrawPiles/YourDecks/Deck, false)
	
	var starv_data = CardInfo.all_cards[0]
	starv_data["attack"] = strength
	if strength >= 5:
		starv_data["sigils"] = ["Repulsive", "Mighty Leap"]
	
	starv_card.from_data(starv_data)
	
	move_done()

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
		
	$Advantage/AdvLeft/PickLeft.rect_position.x = 187 + advantage * 37
	$Advantage/AdvRight/PickRight.rect_position.x = 186 + advantage * (37 if GameOptions.options.show_enemy_advantage else -37)
	
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
		

func clicked_enemy_slot(slot):
	# if no card raised
	# Snipe that slot
	if state == GameStates.SNIPE and snipe_is_attack:
		send_move({
			"type": "snipe_target",
			"from_slot": sniper.slot_idx(),
			"to_slot": slot.get_position_in_parent(),
			"friendly": false
		})
		
		# Do the snipe
		emit_signal("snipe_complete", false, slot.get_position_in_parent())


# Resource visualisation and management
func add_bones(bone_no):
	print("Adding bones ", bones, " => ", bones + bone_no)
	bones += bone_no
	$PlayerInfo/MyInfo/Bones/BoneCount.text = str(bones)
	$PlayerInfo/MyInfo/Bones/BoneCount2.text = str(bones)

func add_opponent_bones(bone_no):
	print("Adding enemy bones ", opponent_bones, " => ", opponent_bones + bone_no)
	opponent_bones += bone_no
	$PlayerInfo/TheirInfo/Bones/BoneCount.text = str(opponent_bones)
	$PlayerInfo/TheirInfo/Bones/BoneCount2.text = str(opponent_bones)

func set_energy(ener_no):
	energy = ener_no
	$PlayerInfo/MyInfo/Energy/AvailableEnergy.rect_size.x = 10 * ener_no
	
func set_opponent_energy(ener_no):
	opponent_energy = ener_no
	$PlayerInfo/TheirInfo/Energy/AvailableEnergy.rect_size.x = 10 * ener_no
	$PlayerInfo/TheirInfo/Energy/AvailableEnergy.rect_position.x = 20 - 20 * ener_no

func set_max_energy(ener_no):
	max_energy = ener_no
	$PlayerInfo/MyInfo/Energy/MaxEnergy.rect_size.x = 10 * (ener_no+max_energy_buff)
	
func set_opponent_max_energy(ener_no):
	opponent_max_energy = ener_no
	$PlayerInfo/TheirInfo/Energy/MaxEnergy.rect_size.x = 10 * (ener_no+opponent_max_energy_buff)
	$PlayerInfo/TheirInfo/Energy/MaxEnergy.rect_position.x = 20 - 20 * (ener_no+opponent_max_energy_buff)


func reload_hand():
	for card in handManager.get_node("PlayerHand").get_children():
		card.from_data(card.card_data)


# CUTSCENES
func moon_cutscene(friendly: bool):
	
	if friendly:
		$MoonFight/AnimationPlayer.play("friendlyMoon")
	else:
		$MoonFight/AnimationPlayer.play("enemyMoon")

	if GameOptions.options.enable_moon_music:
		$MusPlayer.stream = load("res://music/moon.mp3")
		$MusPlayer.play()

# Network interactions
## LOCAL
func request_rematch():
	want_rematch = true
	rpc_id(opponent, "_rematch_requested")
	$WinScreen/Panel/VBoxContainer/HBoxContainer/RematchBtn.text = "Rematch (1/2)"

func surrender():
	
	save_replay()
	
	$WinScreen/Panel/VBoxContainer/WinLabel.text = "You Surrendered!"
	$WinScreen.visible = true
	
	rpc_id(opponent, "_opponent_surrendered")
	
	# Document Result
	get_node("/root/Main/TitleScreen").count_loss(opponent)

func quit_match():
	
	save_replay()
	
	# Tell opponent I surrendered
	rpc_id(opponent, "_opponent_quit")
	
	visible = false
	$MoonFight/AnimationPlayer.play("RESET")
	get_node("/root/Main/TitleScreen").update_lobby()
	
	$MusPlayer.stop()
	
	debug_cleanup()

## REMOTE
remote func _opponent_quit():
	
	save_replay()
	
	# Quit network
	visible = false
	$MoonFight/AnimationPlayer.play("RESET")
	get_node("/root/Main/TitleScreen").update_lobby()
	
	$MusPlayer.stop()
	
	debug_cleanup()
	

remote func _opponent_surrendered():
	
	save_replay()
	
	# Force the game to end
	$WinScreen/Panel/VBoxContainer/WinLabel.text = "Your opponent Surrendered!"
	$WinScreen.visible = true
	
	# Document Result
	get_node("/root/Main/TitleScreen").count_victory()

remote func _opponent_detected_desync():
	# Force the game to end
	$WinScreen/Panel/VBoxContainer/WinLabel.text = "Desync detected!"
	$WinScreen.visible = true

func debug_cleanup():
	# Quit if I'm a debug instance
	if "autoquit" in OS.get_cmdline_args():
		get_tree().quit()
	
	if "DEBUG_HOST" in get_node("PlayerInfo/MyInfo/Username").text and false:
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


func start_turn():
	
	slotManager.initiate_combat(false)
	yield(slotManager, "complete_combat")
	
	slotManager.post_turn_sigils(false)
	yield(slotManager, "resolve_sigils")
	
	damage_stun = false
	$WaitingBlocker.visible = false
	
	# Gold sarcophagus
	for pharoah in gold_sarcophagus:
		if pharoah.turnsleft <= 0:
			draw_card(pharoah.card)
			gold_sarcophagus.erase(pharoah)
		else:
			pharoah.turnsleft -= 1
	
	# Hammers
	if "hammers_per_turn" in CardInfo.all_data and CardInfo.all_data.hammers_per_turn != -1:
		hammers_left = CardInfo.all_data.hammers_per_turn
		$LeftSideUI/HammerButton.text = "Hammer (%d/%d)" % [hammers_left, CardInfo.all_data.hammers_per_turn]
	
	$LeftSideUI/HammerButton.disabled = false

	# Resolve start-of-turn effects
	slotManager.pre_turn_sigils(true)
	yield (slotManager, "resolve_sigils")
	
	move_done()
	
	# Increment energy
	if max_energy < 6:
		set_max_energy(max_energy + 1)
	set_energy(max_energy + max_energy_buff)

	if $MoonFight/BothMoons/FriendlyMoon.visible:
		# Special moon logic
		state = GameStates.NORMAL
		end_turn()
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

