extends PanelContainer

const MAX_HEALTH = 40
const INITIAL_ATK = 1

var attack: int = INITIAL_ATK
var health: int = MAX_HEALTH

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
	update_stats()

func take_damage(dmg: int):
	health -= dmg
	update_stats()

func reset():
	health = MAX_HEALTH
	attack = INITIAL_ATK
	update_stats()

remote func remote_attack(slot: int):
	target = slot
	animPlayer.stop()
	animPlayer.play("enemyMoonSlap")
	
	# TODO: Queue attacks or resolve entirely client-side
