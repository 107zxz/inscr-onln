extends PanelContainer

var attack: int = 1
var health: int = 40

# Slot to hit when attacking
var target = -1

onready var friendly = (name == "FriendlyMoon")

onready var animPlayer = get_node("../../AnimationPlayer")

func update_stats():
	$Attack.text = str(attack)
	$Health.text = str(health)
	
	if health <= 0:
		lunacide()

# I gotta use these fancy half-latin names somewhere
func lunacide():
	print("Lunacide")
	
	# https://youtu.be/IMC0uZY2iH0?t=776
	if friendly:
		animPlayer.play("eggmanFriendly")
	else:
		animPlayer.play("eggmanEnemy")

func _ready():
	
#	if not "The Moon" in CardInfo.all_cards:
#		return
	
	var mn = CardInfo.from_name("The Moon")
	
	if not mn:
		return
	
	attack = mn.attack
	health = mn.health
	
	update_stats()
	
	# Custom portrait
	var d = Directory.new()
	if d.file_exists(CardInfo.portrait_override_path + "The Moon.png"):
		var i = Image.new()
		i.load(CardInfo.portrait_override_path + "The Moon.png")
		var tx = ImageTexture.new()
		tx.create_from_image(i)
		tx.flags -= tx.FLAG_FILTER
		$CBody/Portrait.texture = tx
	elif "pixport_url" in mn:
		var i = Image.new()
		i.load(CardInfo.custom_portrait_path + "The Moon.png")
		var tx = ImageTexture.new()
		tx.create_from_image(i)
		tx.flags -= tx.FLAG_FILTER
		$CBody/Portrait.texture = tx

func take_damage(dmg: int):
	health -= dmg
	update_stats()

func reset():
	var mn = CardInfo.from_name("The Moon")
	
	if not mn:
		return
	
	attack = mn.attack
	health = mn.health
	update_stats()

remote func remote_attack(slot: int):
	target = slot
	animPlayer.stop()
	animPlayer.play("enemyMoonSlap")
	
	# TODO: Queue attacks or resolve entirely client-side

func has_sigil(_sName):
	return false

func is_alive():
	return true
