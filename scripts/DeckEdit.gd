extends Control

var dSize = 0

onready var cardInfo = get_node("/root/Main/AllCards")

onready var searchResults = $HBoxContainer/VBoxContainer/MainArea/SearchResults/VBoxContainer/ScrollContainer/SearchContainer
onready var deckDisplay = $HBoxContainer/VBoxContainer/MainArea/VBoxContainer/DeckPreview/DeckContainer
onready var cardPreview = $HBoxContainer/CardPreview/PreviewContainer

# Search option units
onready var sigil_so_1 = $HBoxContainer/VBoxContainer/DeckOptions/HBoxContainer/SearchOptions/HBoxContainer/VBoxContainer2/SigilSearchA/OptionButton
onready var sigil_so_2 = $HBoxContainer/VBoxContainer/DeckOptions/HBoxContainer/SearchOptions/HBoxContainer/VBoxContainer2/SigilSearchB/OptionButton
onready var cost_type_so = $HBoxContainer/VBoxContainer/DeckOptions/HBoxContainer/SearchOptions/HBoxContainer/VBoxContainer/HBoxContainer2/CTSelect
onready var cost_so = $HBoxContainer/VBoxContainer/DeckOptions/HBoxContainer/SearchOptions/HBoxContainer/VBoxContainer/HBoxContainer/CostSelect
onready var name_so = $HBoxContainer/VBoxContainer/DeckOptions/HBoxContainer/SearchOptions/HBoxContainer/VBoxContainer2/HBoxContainer3/LineEdit

# Deck creation units
onready var selector_de = $HBoxContainer/VBoxContainer/DeckOptions/HBoxContainer/DeckOptions/VBoxContainer/DSelLine/DSel
onready var rename_de = $HBoxContainer/VBoxContainer/DeckOptions/HBoxContainer/DeckOptions/VBoxContainer/DNameLine/LineEdit

# Card result prefab
var cardPrefab = preload("res://packed/dbCard.tscn")

func _on_ExitButton_pressed():
	visible = false
	get_node("/root/Main/Lobby").populate_deck_list()

func _ready():
	init_search_ui()
	search()
	
	ensure_default_deck()
	populate_deck_list()
	get_node("/root/Main/Lobby/").populate_deck_list()
	
	print("DBG: Final load deck call")
	load_deck()

func init_search_ui():
	# Update sigil boxes
	for sb in [sigil_so_1, sigil_so_2]:
		sb.add_item("Any")
		sb.add_item("None")
		for sigil in cardInfo.all_sigils:
			sb.add_item(sigil)
	
	# Populate cost types
	for ct in ["Any", "Blood", "Bones", "Mox"]:
		cost_type_so.add_item(ct)
	
	# Populate cost
	cost_so.add_item("Any")
	for i in range(13):
		cost_so.add_item(str(i))

func search(_arg = null):
	for card in searchResults.get_children():
		card.queue_free()
		
	var resultCount = 0
	
	for card in cardInfo.all_cards:
		# Search conditions
		
		# Name
		if not name_so.text.to_lower() in card["name"].to_lower() and name_so.text != "":
			continue
		
		# Sigils
		if sigil_so_1.text != "Any" and (len(card["sigils"]) == 0 or not sigil_so_1.text in card["sigils"]):
			if not (sigil_so_1.text == "None" and len(card["sigils"]) == 0):
				continue
		if sigil_so_2.text != "Any" and (len(card["sigils"]) == 0 or not sigil_so_2.text in card["sigils"]):
			continue
		
		resultCount += 1
		
		var cObject = cardPrefab.instance()
		cObject.from_data(card)
		searchResults.add_child(cObject)
		
	$HBoxContainer/VBoxContainer/MainArea/SearchResults/VBoxContainer/PanelContainer/ResultsCount.text = str(resultCount) + "/" + str(len(cardInfo.all_cards))

func update_deck_count(var diff = 0):
	dSize += diff
	$HBoxContainer/VBoxContainer/MainArea/VBoxContainer/PanelContainer/DeckSize.text = str(dSize) + "/40"

func _on_ClearButton_pressed():
	for card in deckDisplay.get_children():
		card.queue_free()
	dSize = 0
	update_deck_count()

# Deck Saving and Loading
func get_current_deck_ids():
	var cList = []
	
	for card in deckDisplay.get_children():
		cList.append(get_card_id(card.card_data))
	
	return cList

func get_card_id(card_data):
	return cardInfo.all_cards.find(card_data)

# UI for deck save
func save_deck(_arg = null):
	var sFile = File.new()
	sFile.open(cardInfo.deck_path + selector_de.text + ".deck", File.WRITE)
	sFile.store_line(to_json(get_current_deck_ids()))
	
func save_deck_as(_arg = null):
	if rename_de.text == "":
		return
	
	var sFile = File.new()
	sFile.open(cardInfo.deck_path + rename_de.text + ".deck", File.WRITE)
	sFile.store_line(to_json(get_current_deck_ids()))
	sFile.close()
	
	selector_de.add_item(rename_de.text, selector_de.get_item_count())
	selector_de.select(selector_de.get_item_count() - 1)
	load_deck()

func ensure_default_deck():
	print("DBG: Ensuring default deck is present")
	var fTest = Directory.new()
	var defDeck = File.new()
	
	fTest.open(".")
	
	if not fTest.dir_exists(cardInfo.deck_path):
		print("DBG: Creating decks directory")
		print("Error code: ", fTest.make_dir(cardInfo.deck_path))
	
	if not defDeck.file_exists(cardInfo.deck_path + "default.deck"):
		defDeck.open(cardInfo.deck_path + "default.deck", File.WRITE)
		defDeck.store_line("[]")

func load_deck(_arg = null):
	print("DBG: Load deck called!")
	var dFile = File.new()
	dFile.open(cardInfo.deck_path + selector_de.text + ".deck", File.READ)
	
	for eCard in deckDisplay.get_children():
		eCard.queue_free()
		dSize = 0
	
	var rdj = dFile.get_as_text()
	
	if not parse_json(rdj):
		dFile.open(cardInfo.deck_path + selector_de.text + ".deck", File.WRITE)
		dFile.store_line("[]")
		
		dFile.open(cardInfo.deck_path + selector_de.text + ".deck", File.READ)
		rdj = dFile.get_as_text()
		
	var dj = parse_json(rdj)
	
	for card in dj:
		var nCard = cardPrefab.instance()
		nCard.from_data(cardInfo.all_cards[card])
		deckDisplay.add_child(nCard)
		dSize += 1
	
	update_deck_count()

func populate_deck_list():
	selector_de.clear()
	
	var dTest = Directory.new()
	dTest.open(cardInfo.deck_path)
	dTest.list_dir_begin()
	var fName = dTest.get_next()
	while fName != "":
		if not dTest.current_is_dir() and fName.ends_with(".deck"):
			print("Deck Editor: Found deck ", fName)
			selector_de.add_item(fName.split(".deck")[0])
		fName = dTest.get_next()
