extends PanelContainer

const MAX_HEALTH = 40

var attack: int = 1
var health: int = MAX_HEALTH

onready var friendly = (name == "FriendlyMoon")

onready var animPlayer = get_node("../../AnimationPlayer")

func update_stats():
	$Attack.text = str(attack)
	$Health.text = str(health)
	
	if health <= 0:
		print("Lunacide")
	
func _ready():
	update_stats()

func take_damage(dmg: int):
	health -= dmg
	update_stats()

func reset():
	health = MAX_HEALTH
