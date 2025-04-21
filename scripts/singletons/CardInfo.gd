extends Node

const VERSION = "<VERSION_NUM>"

var all_data = {}
var ruleset = "undefined ruleset"
var all_cards = []

var custom_portraits = {}

var side_decks = {}

#var data_path = OS.get_user_data_dir() # if OS.get_name() != "Android" else "/sdcard/IMF/"

const data_path = "user:/"

const deck_path = data_path + "/decks/"
var deck_backup_path = data_path + "/decks/undef/"
# V Update this! V
var rules_path = ""
const theme_path = data_path + "/theme.json"
const options_path = data_path + "/options.json"
const custom_portrait_path = data_path + "/custom_portraits/"
const custom_icon_path = data_path + "/custom_sigil_icons/"
const portrait_override_path = data_path + "/portrait_overrides/"
const icon_override_path = data_path + "/sigil_icon_overrides/"
const replay_path = data_path + "/replays/"
const rulesets_path = data_path + "/rulesets/"
const scripts_path = data_path + "/scripts/"

# CB
var background_texture = null

# Ruleset data to apply: Used when downloading another player's ruleset
var rs_to_apply = null

# Latest version of game. Used to save a request when updating
var latest_version = ""

func _enter_tree():
	
	var d = Directory.new()
	
	# Hot-patch the game
#	if d.file_exists("user://patch.pck"):
#		ProjectSettings.load_resource_pack("user://patch.pck")
		
	
	if OS.get_name() == "Android":
		if not d.dir_exists(data_path):
			d.make_dir(data_path)
	elif OS.get_name() != "OSX":
		
		var ws = Vector2(1920/2, 1080/2)
		
		OS.window_size = ws
#		OS.window_position += ws
#		OS.window_maximized = false
	
	# optimizations
	Physics2DServer.set_active(false)
	Engine.target_fps = 60
	
#	read_game_info()
	
	# Custom background
	load_background_texture()
	
func load_background_texture():
	var d = Directory.new()
	d.change_dir(data_path)
	for ext in ["png", "jpg"]:
		var path = "%s/background.%s" % [CardInfo.data_path, ext]
		if d.file_exists(path):
			var i = Image.new()
			i.load(path)
			background_texture = ImageTexture.new()
			background_texture.create_from_image(i)

func from_game_info_json(content_as_object):
	all_data = content_as_object
	
	all_data.merge(default_header)
	all_data.last_lane = all_data.lanes_num - 1
	
	all_sigils.merge(all_data["sigils"] if "sigils" in all_data else {}, true)
	all_cards = all_data["cards"]
#	working_sigils = all_data["working_sigils"]

	if "custom_sigils" in all_data:
		for sig in all_data.custom_sigils:
			all_sigils[sig] = all_data.custom_sigils[sig].description
	
	side_decks = all_data["side_decks"] if "side_decks" in all_data else []
	
	if "ruleset" in all_data:
		ruleset = all_data.ruleset
		deck_backup_path = OS.get_user_data_dir() + "/decks/" + ruleset + "/"


func read_game_info():
	
	# Does a downloaded ruleset exist?
	var dir = Directory.new()
	var file = File.new()
	
	if dir.file_exists(rules_path):
		file.open(rules_path, File.READ)
		print(rules_path)
	else:
		print("Downloaded rules not found! Prompting for download")
		get_tree().change_scene("res://packed/AutoUpdate.tscn")
		return
		
	var file_content = file.get_as_text()
	var content_as_object = parse_json(file_content)
	from_game_info_json(content_as_object)

func from_name(cName):
	for card in all_cards:
		if card.name == cName:
			return card

func idx_from_name(cName):
	var idx = 0

	for card in all_cards:
		if card.name == cName:
			return idx
		idx += 1
	
func gen_sig_desc(sigil: String, card_data):
	var sigil_regex = RegEx.new()
	sigil_regex.compile("{(\\w+)}")

	var desc = CardInfo.all_sigils[sigil]
	var var_list = [] # save value to format in later
	
	# get all the formated value
	for res in sigil_regex.search_all(desc):
		var var_name = res.get_string(1)
		if var_name in card_data:
			var_list.append(card_data[var_name])
		else:
			var_list.append("")
			
	desc = sigil_regex.sub(desc, "%s", true) # change the template to godot format
	
	return desc % var_list

const default_header = {
	"hammers_per_turn": -1,
	"num_candles": 2,
	"allow_snuffing_candles": false,
	"snuff_card": "Greater Smoke",

	"ant_limit": 2,
	"variable_attack_nerf": false,
	"opt_actives": false,

	"max_commons_main": 4,
	"max_commons_side": 10,
	"deck_size_min": 1,

	"lanes_num": 4,
	"enable_backrow": false,
	
	"starting_bones": 0,
	"starting_energy_max": 0
}

const all_sigils = {
	# COMMENT THIS OUT
	"Acupuncture": "Pay 3 bones: Choose a creature to gain the Stitched sigil and give this card Armor.",
	"Airborne": "A card bearing this sigil will strike an opponent directly, even if there is a creature opposing it.",
	"Amalgamation": "A card bearing this sigil assimilates the owner's other creatures, gaining their health, power and sigils.",
	"Annoying": "The creature opposing a card bearing this sigil gains 1 Power.",
	"Ant Spawner": "When a card bearing this sigil is played, an ant is created in your hand.",
	"Armored": "The first time a card bearing this sigil would take damage, prevent that damage.",
	"Attack Conduit": "Other creatures within a circuit completed by a card bearing this sigil gain 1 power.",
	"Battery Bearer": "When a card bearing this sigil is played, it provides an energy cell to its owner.",
	"Bees Within": "Once a card bearing this sigil is struck, a Bee is created in your hand.",
	"Bellist": "When a card bearing this sigil is played, a Chime is created on each empty adjacent space. A card bearing this sigil will perform a retaliatory attack against any card striking a Chime.",
	"Bifurcated Strike": "A card bearing this sigil will strike each opposing space to the left and right of the space across from it.",
	"Blood Lust": "When a card bearing this Sigil attacks an opposing creature and it perishes, this card gains 1 power.",
	"Blue Mox": "While a card bearing this sigil is on the board, it provides a blue gem to its owner.",
	"Bomb Latch": "When a card bearing this sigil perishes, its owner chooses a creature to gain the Detonator sigil.",
	"Bomb Spewer": "When a card bearing this sigil is played, fill all empty spaces with explode bots.",
	"Bomb Spewer (Eternal)": "When a card bearing this sigil is played, fill every empty space opposing a card with an explode bot.",
	"Bone Digger": "At the end of the owner's turn, a card bearing this sigil will generate 1 bone.",
	"Bone King": "When a card bearing this sigil dies, 4 bones are awarded instead of 1.",
	"Bonehorn": "Pay 1 energy to gain 3 bones.",
	"Bonehorn (1)": "Pay 1 energy to gain 1 bone.",
	"Boneless": "When a card bearing this sigil dies, no bones are awarded.",
	"Brittle": "After attacking, a card bearing this sigil perishes.",
	"Brittle Latch": "When a card bearing this sigil perishes, its owner chooses a creature to gain the Brittle sigil.",
	"Burrower": "When an empty space would be struck, a card bearing this sigil will move to that space to receive the strike instead.",
	"Corpse Eater": "If a creature that you own perishes by combat, a card bearing this sigil in your hand is automatically played in its place.",
	"Dam Builder": "When a card bearing this sigil is played, a Dam is created on each empty adjacent space.",
	"Depleting": "When a card bearing this sigil is played, 2 energy cells are removed from its owner",
	"Detonator": "When a card bearing this sigil dies, the creature opposing it, as well as adjacent friendly creatures, are dealt 10 damage.",
	"Detonator (5)": "When a card bearing this sigil dies, the creature opposing it, as well as adjacent friendly creatures, are dealt 5 damage.",
	"Disentomb": "Pay 1 bone to create a skeleton in your hand.",
	"Disentomb (Corpses)": "Pay 2 bones to create a withered corpse in your hand.",
	"Double Death": "When another creature you own dies, it is returned to life and dies again immediately.",
	"Double Strike": "A card bearing this Sigil will strike the opposing space an extra time when attacking.",
	"Energy Conduit": "If a card bearing this sigil is part of a completed circuit, your energy never depletes.",
	"Energy Conduit (+3)": "If a card bearing this sigil is part of a completed circuit, your maximum energy increases by 3.",
	"Energy Gun": "Pay 1 energy to deal 1 damage to the creature across from a card bearing this sigil.",
	"Energy Sniper": "Pay 1 energy, this card's owner chooses an opposing creature to take 1 damage.",
	"Energy Gun (Eternal)": "Pay energy to damage the opposing creature until it dies or you run out.",
	"Enlarge": "Pay 2 bones to increase the power and health of a card bearing this sigil by 1.",
	"Enlarge (3)": "Pay 3 bones to increase the power and health of a card bearing this sigil by 1.",
	"Fecundity": "When a card bearing this sigil is played, a copy of it is created in your hand.",
	"Fecundity (Kaycee)": "When a card bearing this sigil is played, a copy of it is created in your hand without this sigil.",
	"Fledgling": "A card bearing this sigil will grow into a more powerful form after 1 turn on the board.",
	"Fledgling 2": "A card bearing this sigil will grow into a more powerful form after 2 turns on the board.",
	"Frozen Away": "When a card bearing this sigil perishes, the creature inside is released in its place.",
	"Gem Animator": "Mox cards on the owner's side of the board gain 1 power.",
	"Gem Dependant": "If a card bearing this sigil's owner controls no mox cards, a card bearing this sigil perishes.",
	"Gem Detonator (5)": "When Mox cards on the owner's side of the board die, they Detonate (the creature opposing them, as well as adjacent friendly creatures, are dealt 5 damage).",
	"Gem Guardian": "When a card bearing this sigil is played, all Moxa cards on the owners' side of the board gain Nano Armor.",
	"Great Mox": "While a card bearing this sigil is on the board, it provides a green, orange, and blue gem to its owner.",
	"Green Mox": "While a card bearing this sigil is on the board, it provides a green gem to its owner.",
	"Guardian": "When an opposing creature is placed opposite to an empty space, a card bearing this sigil will move to that empty space.",
	"Handy": "When a card bearing this sigil is played, discard your hand then draw a new hand of 4 cards.",
	"Hefty": "At the end of the owner's turn, a card bearing this sigil will move in the direction inscribed in the sigil. creatures in the way will be pushed in the same direction.",
	"Hoarder": "When a card bearing this sigil is played, you may search your deck for any card and take it into your hand.",
	"Leader": "Creatures adjacent to a card bearing this sigil gain 1 Power.",
	"Looter": "When a card bearing this sigil deals damage directly, draw a card for each damage dealt.",
	"Made of Stone": "A card bearing this sigil is immune to the effects of touch of death, stinky, annoying and Steel Trap.",
	"Many Lives": "When a card bearing this sigil is sacrificed it does not perish.",
	"Marrow Sucker": "Pay 2 bones to heal a card bearing this sigil.",
	"Mental Gemnastics": "When a card bearing this sigil is played, you draw cards equal to the amount of mox cards on your side of the board.",
	"Mighty Leap": "A card bearing this sigil will block an opposing creature bearing the airborne sigil.",
	"Music Player": "A card bearing this sigil plays a song of your choice when played",
	"Noble Sacrifice": "A card bearing this sigil is counted as 2 blood rather than 1 blood when sacrificed.",
	"Orange Mox": "While a card bearing this sigil is on the board, it provides an orange gem to its owner.",
	"Omni Strike": "A card bearing this sigil will strike all opposing spaces.",
	"Power Dice": "Pay 1 energy to set the power of a card bearing this sigil randomly between 1 and 6.",
	"Power Dice (2)": "Pay 2 energy to set the power of a card bearing this sigil randomly between 1 and 6.",
	"Rabbit Hole": "When a card bearing this sigil is played, a Rabbit is created in your hand.",
	"Reconstitute": "A card bearing this sigil returns to your hand 2 turns after it persihes.",
	"Repulsive": "If a creature would attack a card bearing this sigil, it does not.",
	"Ruby Heart": "When a card bearing this sigil perishes, a ruby mox is created in its place.",
	"Scavenger": "While a card bearing this sigil is alive on the board, opposing creatures also grant you Bones upon death.",
	"Sentry": "When a creature moves into the space opposing a card bearing this sigil, they are dealt 1 damage.",
	"Sharp Quills": "Once a card bearing this sigil is struck, the striker is then dealt a single damage point.",
	"Shield Latch": "When a card bearing this sigil perishes, its owner chooses a creature to gain the Armored sigil.",
	"Side Hustle": "When a card bearing this sigil deals damage directly, draw a card from your side deck for each damage dealt.",
	"Skeleton Crew": "At the end of the owner's turn, a card bearing this sigil will move in the direction inscribed in the sigil and drop a skeleton in its old space.",
	"Skeleton Crew (Yarr)": "At the end of the owner's turn, a card bearing this sigil will move in the direction inscribed in the sigil and drop a pirate skeleton in its old space.",
	"Sniper": "You may choose which opposing card a card bearing this sigil strikes.",
	"Spawn Conduit": "Empty spaces within a circuit completed by a card bearing this sigil spawn L33pB0ts at the end of the owner's turn.",
	"Sprinter": "At the end of the owner's turn, a card bearing this sigil will move in the direction inscribed in the sigil.",
	"Squirrel Shedder": "At the end of the owner's turn, a card bearing this sigil will move in the direction inscribed in the sigil and drop a squirrel in their old space.",
	"Steel Trap": "When a card bearing this sigil perishes, the creature opposing it perishes as well. A Pelt is created in your oppenent's hand.",
	"Stinky": "The creature opposing a card bearing this sigil loses 1 Power.",
	"Stimulate": "Pay 3 energy to increase the power and health of a card bearing this sigil by 1.",
	"Stimulate (4)": "Pay 4 energy to increase the power and health of a card bearing this sigil by 1.",
	"Stitched": "Whenever a card bearing the Acupuncture sigil is damaged, this card recieves that damage, and the Acupuncture card recieves 1 damage instead.",
	"Tentacle": "Includes effect of Waterborne. In addition, a card bearing this sigil will transform into a random tentacle at the start of each turn.",
	"Thick": "A card bearing this sigil is juicy, and takes up 2 spaces.",
	"Touch of Death": "When a card bearing this sigil damages another creature, that creature perishes.",
	"Transformer": "At the beginning of your turn a card bearing this sigil will transform to, or from, Beast mode.",
	"Trifurcated Strike": "A card bearing this sigil will strike each opposing space to the left, right, and center of it.",
	"True Scholar": "If you have a blue gem, sacrifice a card bearing this sigil to draw 3 cards.",
	"Unkillable": "When a card bearing this sigil perishes, a copy of it is created in your hand.",
	"Unkillable (Eternal)": "When a card bearing this sigil perishes, a copy of it is created in your hand without this sigil.",
	"Vessel Printer": "Once a card bearing this sigil is struck, draw a card from your side deck.",
	"Warded": "A card bearing this sigil takes only 1 damage from attacks and card effects.",
	"Waterborne": "A card bearing this sigil submerges itself during its opponent's turn. while submerged, opposing creatures attack its owner directly.",
	"Worthy Sacrifice": "A card bearing this sigil is counted as 3 blood rather than 1 blood when sacrificed."
}

const working_sigils = [
	"Airborne",
	"Mighty Leap",
	"Fecundity (Kaycee)",
	"Fecundity",
	"Unkillable",
	"Blue Mox",
	"Green Mox",
	"Orange Mox",
	"Great Mox",
	"Rabbit Hole",
	"Touch of Death",
	"Many Lives",
	"Trifurcated Strike",
	"Battery Bearer",
	"Repulsive",
	"Brittle",
	"Worthy Sacrifice",
	"Gem Dependant",
	"Bone King",
	"Bifurcated Strike",
	"Handy",
	"Fledgling",
	"Sprinter",
	"Squirrel Shedder",
	"Skeleton Crew",
	"Bone Digger",
	"Waterborne",
	"Ruby Heart",
	"Frozen Away",
	"Mental Gemnastics",
	"Looter",
	"Gem Animator",
	"Hefty",
	"Guardian",
	"Sharp Quills",
	"Sentry",
	"Burrower",
	"Hoarder",
	"Detonator",
	"Detonator (5)",
	"Bomb Spewer",
	"Double Death",
	"Enlarge",
	"Disentomb",
	"Disentomb (Corpses)",
	"Power Dice",
	"Power Dice (2)",
	"Stimulate",
	"Stimulate (4)",
	"Energy Gun",
	"True Scholar",
	"Bonehorn",
	"Bonehorn (1)",
	"Boneless",
	"Attack Conduit",
	"Spawn Conduit",
	"Energy Conduit",
	"Energy Conduit (+3)",
	"Tentacle",
	"Stinky",
	"Reconstitute",
	"Noble Sacrifice",
	"Made of Stone",
	"Side Hustle",
	"Armored",
	"Leader",
	"Ant Spawner",
	"Double Strike",
	"Blood Lust",
	"Music Player",
	"Transformer",
	"Vessel Printer",
	"Bees Within",
	"Dam Builder",
	"Corpse Eater",
	"Gem Guardian",
	"Gem Detonator (5)",
	"Depleting",
	"Bellist",
	"Omni Strike",
	"Enlarge (3)",
	"Skeleton Crew (Yarr)",
	"Thick",
	"Annoying",
	"Steel Trap",
	"Scopophobic",
	"Scavenger",
	"Amalgamation",
	"Unkillable (Eternal)",
	"Energy Gun (Eternal)",
	"Bomb Spewer (Eternal)",
	"Sniper",
	"Brittle Latch",
	"Bomb Latch",
	"Shield Latch",
	"Fledgling 2",
	"Energy Sniper",
	"Warded",
	"Acupuncture",
	"Stitched"
]

const keywords = {
	"rare": "Rare: You may only use one copy of this card in your deck.",
	"nosac": "Terrain: This card cannot be sacrificed.",
	"nohammer": "Unhammerable: This card cannot be hammered.",
	"conduit": "Conduit: This card completes a circuit. At least 2 circuit completing cards are needed to complete a circuit."
}
