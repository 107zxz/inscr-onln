extends Control

onready var tree = get_node("%RulesetTree")
var cardRoot = null
var sigilRoot = null

onready var cardDats = get_node("%CardDat").get_children()
onready var flagDats = get_node("%Options").get_children()

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
	
	var root = tree.create_item()
	
	root.set_text(0, CardInfo.ruleset)
	
	cardRoot = tree.create_item(root)
	cardRoot.set_text(0, "Cards")
	
	# TODO: Add support for side decks

	root.select(0)
	
	populate_cards()
	populate_flags()
	
func populate_cards():
	for card in CardInfo.all_cards:
		tree.create_item(cardRoot).set_text(0, card.name)
		cardDats[21].add_item(card.name)
		cardNames.append(card.name)

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
#	cardDats[0].texture = load("res://gfx/pixport/" + current_card.name + ".png")
	load_pixport()
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
	
	if "description" in current_card:
		cardDats[24].text = current_card.description
	else:
		cardDats[24].text = ""

func save_card_changes(_xtra = null):
	
	if not tree.get_selected():
		return
		
	if not tree.get_selected().get_parent() or tree.get_selected().get_parent().get_text(0) != "Cards":
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
		
	if cardDats[24].text != "":
		current_card.description = cardDats[24].text
	else:
		current_card.erase("description")
	
	# Sigils
	if cardDats[4].selected != 0 or cardDats[5].selected != 0:
		current_card.sigils = []
		
		if cardDats[4].selected != 0:
			current_card.sigils.append(cardDats[4].text)
			
		if cardDats[5].selected != 0:
			current_card.sigils.append(cardDats[5].text)
	else:
		current_card.erase("sigils")
	
#	cardDats[0].texture = load("res://gfx/pixport/" + current_card.name + ".png")
	load_pixport()
	
#	$Error/PanelContainer/VBoxContainer/Label.text = JSON.print(current_card)
#	$Error.show()
	
func exit_editor():
#	$SaveDialog.popup_centered()
	get_tree().change_scene("res://packed/RulesetPickerProto.tscn")

func _on_SaveDialog_file_selected(path):
	
	save_card_changes()
	
	# Apply flags before saving
	update_flags()
	
	var ss = path.split("/")
	
	CardInfo.all_data.ruleset = ss[len(ss)-1].split(".json")[0]
	
	var f = File.new()
	
	f.open(path, File.WRITE)
	f.store_string(JSON.print(CardInfo.all_data, "\t"))
	f.close()
	
	update_portrait_names()

func update_portrait_names():
	var d = Directory.new()
	d.open(CardInfo.custom_portrait_path)
	d.list_dir_begin()
	var fn = d.get_next()
	while fn != "":
		
		if not d.current_is_dir() and fn.begins_with("RSTMP_"):
			var new_name = CardInfo.all_data.ruleset + fn.substr(5)
			d.rename(fn, new_name)
		 
		
		fn = d.get_next()

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
	
	var cIdx = 1
	var selNxt = false
	
	for card in CardInfo.all_cards:
		var ni = tree.create_item(cardRoot)
		ni.set_text(0, card.name)
		cardDats[21].add_item(card.name)
		
		if selNxt:
			ni.select(0)
		
		if card.name == cc:
			
			# IMPORTANT: Add card to ruleset at position and with different name
			
			CardInfo.all_cards.insert(cIdx, card.duplicate())
			CardInfo.all_cards[cIdx].name += " 2"
			
			selNxt = true
			
#			var ni = tree.create_item(cardRoot)
#			ni.set_text(0, card.name + " 2")
#			ni.select(0)
#			cardDats[21].add_item(card.name + " 2")
			
			
		
		cIdx += 1
	
func _on_Remove_pressed():
	var nxt = tree.get_selected().get_next()
	cardRoot.remove_child(tree.get_selected())
	nxt.select(0)


func _on_PortURL_focus_exited():
	_on_PortURL_text_entered($Cards/Panel/CardDat/PortURL.text)


func _on_PortURL_text_entered(new_text):
	var d = Directory.new()
#	var fp = CardInfo.custom_portrait_path + CardInfo.all_data.ruleset + "_" + $Cards/Panel/CardDat/Name.text + ".png"
	var fp = CardInfo.custom_portrait_path + "RSTMP_" + $Cards/Panel/CardDat/Name.text + ".png"
	
	if d.file_exists(fp):
		d.remove(fp)
	
	if new_text == "":
		load_pixport()
		return
	
	$Status.show()
	
	$PixportRequest.download_file = fp
	
	if $PixportRequest.request(new_text) == OK:
		yield($PixportRequest, "request_completed")
		load_pixport()
	
	$Status.hide()

func load_pixport():
	var d = Directory.new()
	
#	if d.file_exists(CardInfo.custom_portrait_path + CardInfo.all_data.ruleset + "_" + current_card.name + ".png"):
	if d.file_exists(CardInfo.custom_portrait_path + "RSTMP_" + current_card.name + ".png"):
		var i = Image.new()
#		i.load(CardInfo.custom_portrait_path + CardInfo.all_data.ruleset + "_" + current_card.name + ".png")
		i.load(CardInfo.custom_portrait_path + "RSTMP_" + current_card.name + ".png")
		var tx = ImageTexture.new()
		tx.create_from_image(i)
		tx.flags -= tx.FLAG_FILTER
		cardDats[0].texture = tx
	elif d.file_exists("res://gfx/pixport/" + current_card.name + ".png"):
		cardDats[0].texture = load("res://gfx/pixport/" + current_card.name + ".png")
	else:
		cardDats[0].texture = null

# Smaller function to update flags
func update_flags():
	CardInfo.all_data.num_candles = flagDats[1].value
	CardInfo.all_data.allow_snuffing_candles = flagDats[3].pressed
	CardInfo.all_data.snuff_card = flagDats[5].text
	CardInfo.all_data.hammers_per_turn = flagDats[7].value
	CardInfo.all_data.deck_size_min = flagDats[9].value
	CardInfo.all_data.max_commons_main = flagDats[11].value
	CardInfo.all_data.max_commons_side = flagDats[13].value
	CardInfo.all_data.variable_attack_nerf = flagDats[15].pressed
	
	if flagDats[15].pressed:
		CardInfo.all_data.necro_boned = true
	else:
		CardInfo.all_data.erase("necro_boned")
	CardInfo.all_data.ant_limit = flagDats[19].value
	CardInfo.all_data.description = flagDats[20].text
	CardInfo.all_data.portrait = flagDats[22].text
	
	if flagDats[25].value != 0:
		CardInfo.all_data.starting_bones = flagDats[25].value
	else:
		CardInfo.all_data.erase("starting_bones")
		
	if flagDats[27].value != 0:
		CardInfo.all_data.starting_energy_max = flagDats[27].value
	else:
		CardInfo.all_data.erase("starting_energy_max")

func populate_flags():
	flagDats[1].value = CardInfo.all_data.num_candles
	flagDats[3].pressed = CardInfo.all_data.allow_snuffing_candles
	flagDats[5].text = CardInfo.all_data.snuff_card if "snuff_card" in CardInfo.all_data else ""
	flagDats[7].value = CardInfo.all_data.hammers_per_turn
	flagDats[9].value = CardInfo.all_data.deck_size_min
	flagDats[11].value = CardInfo.all_data.max_commons_main
	flagDats[13].value = CardInfo.all_data.max_commons_side
	flagDats[15].pressed = CardInfo.all_data.variable_attack_nerf
	flagDats[17].pressed = "necro_boned" in CardInfo.all_data
	flagDats[19].value = CardInfo.all_data.ant_limit
	flagDats[20].text = CardInfo.all_data.description
	
	if "starting_bones" in CardInfo.all_data:
		flagDats[25].value = CardInfo.all_data.starting_bones
	
	if "starting_energy_max" in CardInfo.all_data:
		flagDats[27].value = CardInfo.all_data.starting_energy_max
	
	
	
	# Fill out possible icons
	var d = Directory.new()
	d.open("res://gfx/portraits")
	d.list_dir_begin()
	var file_name = d.get_next()
	
	var idx = 0
	
	while file_name != "":
		
		if file_name.ends_with(".png"):
			flagDats[22].add_item("portraits/" + file_name.split(".png")[0])
			
			if flagDats[22].get_item_text(idx) == CardInfo.all_data.portrait:
				flagDats[22].select(idx)
			
			idx += 1
			
		file_name = d.get_next()
	d.list_dir_end()
	
#	flagDats[18].text = CardInfo.all_data.portrait
