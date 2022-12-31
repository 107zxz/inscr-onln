extends Control

onready var tree = get_node("%RulesetTree")
var cardRoot = null
var sigilRoot = null

onready var cardDats = get_node("%CardDat").get_children()
onready var rulesetDats = get_node("%Options").get_children()

var cardNames = []
var specialAttacks = [
	"ant",
	"mox",
	"green_mox",
	"mirror"
]

var current_card = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	
	$SaveDialog.current_dir = "user://rulesets/"
	
	# Fill Sigils
	var idx = 1
	for sigil in CardInfo.all_sigils.keys():
		cardDats[4].add_item(sigil, idx)
		cardDats[5].add_item(sigil, idx)
	
	var root = tree.create_item()
	
	root.set_text(0, CardInfo.ruleset)
	
	cardRoot = tree.create_item(root)
	sigilRoot = tree.create_item(root)
	cardRoot.set_text(0, "Cards")
	sigilRoot.set_text(0, "Sigils")
	
#	cardRoot.collapsed = true
	sigilRoot.collapsed = true
#	root.collapsed = true
	
	populate_cards()
	populate_sigils()
	
func populate_cards():
	for card in CardInfo.all_cards:
		tree.create_item(cardRoot).set_text(0, card.name)
		cardDats[21].add_item(card.name)
		cardNames.append(card.name)

func populate_sigils():
	for sigil in CardInfo.all_sigils:
		var i = tree.create_item(sigilRoot)
		i.set_text(0, sigil)
#		i.set_text(1, CardInfo.all_sigils[sigil])

func _on_RulesetTree_item_selected():
	
	if tree.get_selected().get_parent():
		if tree.get_selected().get_parent().get_text(0) == "Cards":
			draw_card()
	
	if tree.get_selected() == tree.get_root():
		draw_ruleset()
	

func draw_ruleset():
	get_node("%Options").visible = true
	get_node("%CardDat").visible = false

func draw_card():
	get_node("%CardDat").visible = true
	get_node("%Options").visible = false
	
	current_card = CardInfo.from_name(tree.get_selected().get_text(0))
	
	# TODO
	cardDats[0].texture = load("res://gfx/pixport/" + current_card.name + ".png")
	cardDats[1].value = current_card.attack
	cardDats[2].value = current_card.health
	cardDats[3].text = current_card.name
	
	if "sigils" in current_card:
		cardDats[4].select(1+CardInfo.all_sigils.keys().find(current_card.sigils[0]))
		if current_card.sigils.size() > 1:
			cardDats[5].select(1+CardInfo.all_sigils.keys().find(current_card.sigils[1]))
		else:
			cardDats[5].select(0)
	else:
		cardDats[4].select(0)
		cardDats[5].select(0)
	
	cardDats[6].value = current_card.blood_cost if "blood_cost" in current_card else 0
	cardDats[8].value = current_card.bone_cost if "bone_cost" in current_card else 0
	cardDats[10].value = current_card.energy_cost if "energy_cost" in current_card else 0
	
	if "mox_cost" in current_card:
		cardDats[12].pressed = "Orange" in current_card.mox_cost
		cardDats[13].pressed = "Green" in current_card.mox_cost
		cardDats[14].pressed = "Blue" in current_card.mox_cost
	else:
		cardDats[12].pressed = false
		cardDats[13].pressed = false
		cardDats[14].pressed = false
	
	cardDats[15].pressed = not "banned" in current_card
	cardDats[16].pressed = "rare" in current_card
	cardDats[17].pressed = "nosac" in current_card
	cardDats[18].pressed = "nohammer" in current_card
	cardDats[19].pressed = "conduit" in current_card
	
#	cardDats[21].text = cDat.evolution if "evolution" in cDat else ""
	if "evolution" in current_card:
		cardDats[21].select(cardNames.find(current_card.evolution) + 1)
	else:
		cardDats[21].select(0)
	
	if "atkspecial" in current_card:
		cardDats[22].select(specialAttacks.find(current_card.atkspecial) + 1)
	else:
		cardDats[22].select(0)
		
	if "pixport_url" in current_card:
		cardDats[23].text = current_card.pixport_url
	else:
		cardDats[23].text = ""
	
#	cardDats[22].select(cDat.atkspecial + 1 if "atkspecial" in cDat else 0)
#	TODO: Make this use the string

func save_card_changes():
	
	if not tree.get_selected():
		return
	
	tree.get_selected().set_text(0, cardDats[3].text)
	
	current_card.attack = int(cardDats[1].value)
	current_card.health = int(cardDats[2].value)
	current_card.name = cardDats[3].text
	
	# Update name in evo picker
	cardDats[21].clear()
	cardDats[21].add_item("None")
	for card in CardInfo.all_cards:
		cardDats[21].add_item(card.name)
	
	current_card.blood_cost = cardDats[6].value
	current_card.bone_cost = cardDats[8].value
	current_card.energy_cost = cardDats[10].value
	
	if cardDats[6].value == 0:
		current_card.erase("blood_cost")
	if cardDats[8].value == 0:
		current_card.erase("bone_cost")
	if cardDats[10].value == 0:
		current_card.erase("energy_cost")
	
	# 12 - 14 MOX
	if cardDats[12].pressed or cardDats[13].pressed or cardDats[14].pressed:
		current_card.mox_cost = []
		if cardDats[12].pressed:
			current_card.mox_cost.append("Orange")
		if cardDats[13].pressed:
			current_card.mox_cost.append("Green")
		if cardDats[14].pressed:
			current_card.mox_cost.append("Blue")
	else:
		current_card.erase("mox_cost")
	
	# 15-19 flags
	if not cardDats[15].pressed:
		current_card.banned = true
	else:
		current_card.erase("banned")
	if cardDats[16].pressed:
		current_card.rare = true
	else:
		current_card.erase("rare")
	if cardDats[17].pressed:
		current_card.nosac = true
	else:
		current_card.erase("nosac")
	if cardDats[18].pressed:
		current_card.nohammer = true
	else:
		current_card.erase("nohammer")
	if cardDats[19].pressed:
		current_card.conduit = true
	else:
		current_card.erase("conduit")
	
	# Evo
	if cardDats[21].selected > 0:
		current_card.evolution = cardDats[21].text
	else:
		current_card.erase("evolution")
	
	# Specialatk
	if cardDats[22].selected > 0:
		current_card.atkspecial = specialAttacks[cardDats[22].selected-1]
	else:
		current_card.erase("atkspecial")
	
	# Pixport url
	if cardDats[23].text != "":
		current_card.pixport_url = cardDats[23].text
	else:
		current_card.erase("pixport_url")
	
	# Sigils
	if cardDats[4].selected != 0 or cardDats[5].selected != 0:
		current_card.sigils = []
		
		if cardDats[4].selected != 0:
			current_card.sigils.append(cardDats[4].text)
			
		if cardDats[5].selected != 0:
			current_card.sigils.append(cardDats[5].text)
	else:
		current_card.erase("sigils")
	
	cardDats[0].texture = load("res://gfx/pixport/" + current_card.name + ".png")
	
#	$Error/PanelContainer/VBoxContainer/Label.text = JSON.print(current_card)
#	$Error.show()
	
func exit_editor():
#	$SaveDialog.popup_centered()
	get_tree().change_scene("res://packed/RulesetPickerProto.tscn")

func _on_SaveDialog_file_selected(path):
	
	print("\"", path, "\"")
	
	var ss = path.split("/")
	
	CardInfo.all_data.ruleset = ss[len(ss)-1].split(".json")[0]
	
	var f = File.new()
	
	f.open(path, File.WRITE)
	f.store_string(JSON.print(CardInfo.all_data))
	f.close()

func _on_MoveUp_pressed():
	var current = tree.get_selected()
	var prev = current.get_prev()
	
	if not prev:
		return
	
	var txCache = current.get_text(0)
	
	current.set_text(0, prev.get_text(0))
	prev.set_text(0, txCache)
	
	prev.select(0)

func _on_MoveDown_pressed():
	var current = tree.get_selected()
	var next = current.get_next()
	
	if not next:
		return
	
	var txCache = current.get_text(0)
	
	current.set_text(0, next.get_text(0))
	next.set_text(0, txCache)
	
	next.select(0)

func _on_Duplicate_pressed():
	var cc = tree.get_selected().get_text(0)
	
	var child = cardRoot.get_children()
	
	while child != null:
		cardRoot.remove_child(child)
		child = child.get_next()
		
	cardDats[21].clear()
	cardDats[21].add_item("None")
	
	for card in CardInfo.all_cards:
		tree.create_item(cardRoot).set_text(0, card.name)
		cardDats[21].add_item(card.name)
		
		if card.name == cc:
			
			# IMPORTANT: Add card to ruleset at position and with different name
			
			var ni = tree.create_item(cardRoot)
			ni.set_text(0, card.name + " 2")
			ni.select(0)
			cardDats[21].add_item(card.name + " 2")
	
func _on_Remove_pressed():
	var nxt = tree.get_selected().get_next()
	cardRoot.remove_child(tree.get_selected())
	nxt.select(0)
