extends Control

onready var tree = get_node("%RulesetTree")
var cardRoot = null
var sigilRoot = null

onready var cardDats = get_node("%CardDat").get_children()
onready var rulesetDats = get_node("%Options").get_children()

# Called when the node enters the scene tree for the first time.
func _ready():
	
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
	
	var cDat = CardInfo.from_name(tree.get_selected().get_text(0))
	
	# TODO
	cardDats[0].texture = load("res://gfx/pixport/" + cDat.name + ".png")
	cardDats[1].value = cDat.attack
	cardDats[2].value = cDat.health
	cardDats[3].text = cDat.name
	
	if "sigils" in cDat:
		cardDats[4].select(1+CardInfo.all_sigils.keys().find(cDat.sigils[0]))
		if cDat.sigils.size() > 1:
			cardDats[5].select(1+CardInfo.all_sigils.keys().find(cDat.sigils[1]))
		else:
			cardDats[5].select(0)
	else:
		cardDats[4].select(0)
		cardDats[5].select(0)
	
	cardDats[6].value = cDat.blood_cost if "blood_cost" in cDat else 0
	cardDats[8].value = cDat.bone_cost if "bone_cost" in cDat else 0
	cardDats[10].value = cDat.energy_cost if "energy_cost" in cDat else 0
	
	if "mox_cost" in cDat:
		cardDats[12].pressed = "Orange" in cDat.mox_cost
		cardDats[13].pressed = "Green" in cDat.mox_cost
		cardDats[14].pressed = "Blue" in cDat.mox_cost
	else:
		cardDats[12].pressed = false
		cardDats[13].pressed = false
		cardDats[14].pressed = false
	
	cardDats[15].pressed = not "banned" in cDat
	cardDats[16].pressed = "rare" in cDat
	cardDats[17].pressed = "nosac" in cDat
	cardDats[18].pressed = "nohammer" in cDat
	cardDats[19].pressed = "conduit" in cDat
	
#	cardDats[21].text = cDat.evolution if "evolution" in cDat else ""
	
#	cardDats[22].select(cDat.atkspecial + 1 if "atkspecial" in cDat else 0)
#	TODO: Make this use the string

func exit_editor():
	get_tree().change_scene("res://packed/RulesetPickerProto.tscn")
