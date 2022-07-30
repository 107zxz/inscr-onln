extends Control

var dSize = 0

onready var searchResults = get_node("%SearchContainer")
onready var deckDisplay = get_node("%DeckContainer")
onready var cardPreview = get_node("%PreviewContainer")

# Search option units
onready var searchOptions = get_node("%SearchOptions")

onready var sigil_so_1 = searchOptions.get_node("HBoxContainer/VBoxContainer2/SigilSearchA/OptionButton")
onready var sigil_so_2 = searchOptions.get_node("HBoxContainer/VBoxContainer2/SigilSearchB/OptionButton")
onready var cost_type_so = searchOptions.get_node("HBoxContainer/VBoxContainer/HBoxContainer2/CTSelect")
onready var name_so = searchOptions.get_node("HBoxContainer/VBoxContainer2/HBoxContainer3/LineEdit")

# Deck creation units
onready var selector_de = $HBoxContainer/VBoxContainer/DeckOptions/HBoxContainer/DeckOptions/VBoxContainer/DSelLine/DSel
onready var rename_de = $HBoxContainer/VBoxContainer/DeckOptions/HBoxContainer/DeckOptions/VBoxContainer/DNameLine/LineEdit

# Extended options
onready var sidedeck_de = $HBoxContainer/VBoxContainer/MainArea/VBoxContainer/DeckPreview2/VBoxContainer/HBoxContainer/SDSel
onready var sidedeck_container = $HBoxContainer/VBoxContainer/MainArea/VBoxContainer/DeckPreview2/VBoxContainer/MoxContainer
onready var sidedeck_single = get_node("%SDCardSingle")


# const sdCards = [30, 82, 112, -1, -1, 120, 121, 122]
const sdCards = ["Squirrel", "Skeleton", "Empty Vessel", "", "", "Geck", "Acid Squirrel", "Shambling Cairn", "Magnus Mox"]

# Card result prefab
var cardPrefab = preload("res://packed/dbCard.tscn")

func _on_ExitButton_pressed():
	visible = false
	get_node("/root/Main/TitleScreen").populate_deck_list()
	get_node("/root/Main/TitleScreen").select_deck(selector_de.selected)

func _ready():
	init_search_ui()
	search()
	
	ensure_default_deck()
	populate_deck_list()
	get_node("/root/Main/TitleScreen").populate_deck_list()
	
	load_deck()

func init_search_ui():
	var id = 2
	
	# Update sigil boxes
	for sb in [sigil_so_1, sigil_so_2]:
		sb.add_item("Any", 0)
		sb.add_item("None", 1)
		for sigil in CardInfo.all_sigils:
			sb.add_item(sigil, id)
			id += 1

func search(_arg = null):
	for card in searchResults.get_children():
		card.queue_free()
		
	var resultCount = 0
	
	for card in CardInfo.all_cards:
		# Don't show banned cards
		if "banned" in card:
			continue

		# Search conditions
		
		# Name
		if not name_so.text.to_lower() in card["name"].to_lower() and name_so.text != "":
			continue
		
		# Sigils
		if sigil_so_1.text != "Any" and (not "sigils" in card or not sigil_so_1.text in card["sigils"]):
			if not (sigil_so_1.text == "None" and not "sigils" in card):
				continue
		if sigil_so_2.text != "Any" and (not "sigils" in card or not sigil_so_2.text in card["sigils"]):
			continue
		# Cost type
		if cost_type_so.selected == 1 and not "blood_cost" in card:
			continue
		if cost_type_so.selected == 2 and not "bone_cost" in card:
			continue
		if cost_type_so.selected == 3 and not "energy_cost" in card:
			continue
		if cost_type_so.selected == 4 and not "mox_cost" in card:
			continue
		
		resultCount += 1
		
		var cObject = cardPrefab.instance()
		cObject.from_data(card)
		
		searchResults.add_child(cObject)
		
	$HBoxContainer/VBoxContainer/MainArea/SearchResults/VBoxContainer/PanelContainer/ResultsCount.text = str(resultCount) + "/" + str(len(CardInfo.all_cards))

func update_deck_count(var diff = 0):
	dSize += diff
	$HBoxContainer/VBoxContainer/MainArea/VBoxContainer/PanelContainer/DeckSize.text = str(dSize)

func _on_ClearButton_pressed():
	for card in deckDisplay.get_children():
		card.queue_free()
	dSize = 0
	update_deck_count()

# Deck Saving and Loading
func get_deck_object():
	
	var side_deck = sidedeck_de.selected
	
	# Side deck
	if side_deck == 3:
		side_deck = []
		for card in sidedeck_container.get_children():
			side_deck.append(get_card_id(card.card_data))
	
	var deck_object = {
		"cards": [],
		"side_deck": side_deck
	}
	
	# More side deck
	if typeof(side_deck) == TYPE_INT and side_deck == 2:
		deck_object["vessel_type"] = CardInfo.all_cards.find(sidedeck_single.card_data)
	
	for card in deckDisplay.get_children():
		deck_object["cards"].append(card.card_data["name"])
	
	return deck_object

func get_card_count(cDat):
	var res = 0

	for card in deckDisplay.get_children():
		if card.card_data == cDat:
			res += 1
	
	return res

func get_card_id(card_data):
	return CardInfo.all_cards.find(card_data)

# UI for deck save
func save_deck(_arg = null):
	
	var sFile = File.new()
	sFile.open(CardInfo.deck_path + selector_de.text + ".deck", File.WRITE)
	sFile.store_line(to_json(get_deck_object()))
	
func save_deck_as(_arg = null):
	if rename_de.text == "":
		return

	var dTest : Directory = Directory.new()
	if not dTest.file_exists(CardInfo.deck_path + rename_de.text + ".deck"):
		selector_de.add_item(rename_de.text, selector_de.get_item_count())	
	
	var sFile: File = File.new()
	sFile.open(CardInfo.deck_path + rename_de.text + ".deck", File.WRITE)
	sFile.store_line(to_json(get_deck_object()))
	sFile.close()
	
	for item in range(selector_de.get_item_count()):
		if selector_de.get_item_text(item) == rename_de.text:
			selector_de.select(item)

	load_deck()

func ensure_default_deck():
	var fTest = Directory.new()
	var defDeck = File.new()
	
	fTest.open(".")
	
	if not fTest.dir_exists(CardInfo.deck_path):
		print("Creating deck directory! Error code: ", fTest.make_dir(CardInfo.deck_path))
	
	if not defDeck.file_exists(CardInfo.deck_path + "default.deck"):
		defDeck.open(CardInfo.deck_path + "default.deck", File.WRITE)
		defDeck.store_line("{\"cards\": [], \"side_deck\": 0}\n")

func load_deck(_arg = null):
	var dFile = File.new()
	dFile.open(CardInfo.deck_path + selector_de.text + ".deck", File.READ)
	
	for eCard in deckDisplay.get_children():
		eCard.queue_free()
		dSize = 0
	
	var rdj = dFile.get_as_text()
	
	if not parse_json(rdj):
		dFile.open(CardInfo.deck_path + selector_de.text + ".deck", File.WRITE)
		dFile.store_line("{\"cards\": [], \"side_deck\": 0}\n")
		
		dFile.open(CardInfo.deck_path + selector_de.text + ".deck", File.READ)
		rdj = dFile.get_as_text()
		
	var dj = parse_json(rdj)
	
	for card in dj["cards"]:
		var nCard = cardPrefab.instance()
		
		if typeof(card) == TYPE_STRING:
			nCard.from_data(CardInfo.from_name(card))
		else:
			nCard.from_data(CardInfo.all_cards[card])
		deckDisplay.add_child(nCard)
		dSize += 1
	
	# Mox
	for child in sidedeck_container.get_children():
		child.queue_free()
	
	if typeof(dj["side_deck"]) == TYPE_ARRAY:
		sidedeck_de.select(3)
		
		sidedeck_single.visible = false
		get_node("%CustomizeLabel").visible = true
		sidedeck_container.visible = true
		for i in range(10):
			var nCard = cardPrefab.instance()
			nCard.from_data(CardInfo.all_cards[dj["side_deck"][i]])
			sidedeck_container.add_child(nCard)
	else:
		sidedeck_single.visible = true
		sidedeck_container.visible = false
		
		# Banned
		if sidedeck_de.is_item_disabled(dj["side_deck"]):
			sidedeck_de.select(0)
		else:
			sidedeck_de.select(dj["side_deck"])
		
		# More mox

		var bMox = CardInfo.from_name("Sapphire Mox")
		var oMox = CardInfo.from_name("Ruby Mox")
		var gMox = CardInfo.from_name("Emerald Mox")

		for mId in [gMox, gMox, gMox, oMox, oMox, oMox, bMox, bMox, bMox, bMox]:
			var nCard = cardPrefab.instance()
			nCard.from_data(mId)
			sidedeck_container.add_child(nCard)
		
		# Also setup the other card
		sidedeck_single.from_data(CardInfo.from_name( sdCards[ dj["side_deck"]] ))
		
		if "vessel_type" in dj:
			sidedeck_single.from_data(CardInfo.all_cards[dj["vessel_type"]])
			get_node("%CustomizeLabel").visible = true
		else:
			get_node("%CustomizeLabel").visible = false
	
	update_deck_count()

func populate_deck_list():
	var prevSelected = ""
	
	if selector_de.selected >= 0:
		prevSelected = selector_de.get_item_text(selector_de.selected)

	selector_de.clear()
	
	var dTest = Directory.new()
	dTest.open(CardInfo.deck_path)
	dTest.list_dir_begin()
	var fName = dTest.get_next()
	while fName != "":
		if not dTest.current_is_dir() and fName.ends_with(".deck"):
			selector_de.add_item(fName.split(".deck")[0])
		fName = dTest.get_next()
	
	# Re-select deck
	for item_idx in range(selector_de.get_item_count()):
		if selector_de.get_item_text(item_idx) == prevSelected:
			selector_de.select(item_idx)


func _on_SDSel_item_selected(index):
	if index == 3:
		sidedeck_container.visible = true
		sidedeck_single.visible = false
		
		get_node("%CustomizeLabel").visible = true
	else:
		sidedeck_container.visible = false
		sidedeck_single.visible = true
		
		sidedeck_single.from_data(CardInfo.from_name( sdCards[ sidedeck_de.selected ] ))
		
		if index == 2:
			get_node("%CustomizeLabel").visible = true
		else:
			get_node("%CustomizeLabel").visible = false	
			


func _on_SortButton_pressed():
	for eCard in deckDisplay.get_children():
		eCard.queue_free()
	
	var cardList = get_deck_object()["cards"]
	
	cardList.sort()
	
	for card in cardList:
		var nCard = cardPrefab.instance()
		nCard.from_data(CardInfo.from_name(card))
		deckDisplay.add_child(nCard)
		dSize += 1
		
func _on_ShuffleButton_pressed():
	for eCard in deckDisplay.get_children():
		eCard.queue_free()
	
	var cardList = get_deck_object()["cards"]
	
	cardList.shuffle()
	
	for card in cardList:
		var nCard = cardPrefab.instance()
		nCard.from_data(CardInfo.from_name(card))
		deckDisplay.add_child(nCard)
		dSize += 1

func _on_ViewFolder_pressed():
	print(CardInfo.deck_path)
	OS.shell_open("file://" + CardInfo.deck_path)
