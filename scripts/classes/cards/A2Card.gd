extends Control

const HVR_COLOURS = [
	Color(0.933333, 0.921569, 0.843137),
	Color.white,
	Color(0.45, 0.45, 0.45)
]

const SIGIL_SLOTS = [
	"Sigils/Row1/S1",
	"Sigils/Row1/S2",
	"Sigils/Row1/S3",
	
	"Sigils/Row2/S1",
	"Sigils/Row2/S2",
	"Sigils/Row2/S3"
]

#var card_data = {
#	"name": "Buff Conduit",
#	"stats": [1, 2],
#	"costs": {
#		"bone": 2
#	},
#	"sigils": [
#		"Disentomb"
#	],
#	"traits": [
#		"active"
#	]
#}

## Called when the node enters the scene tree for the first time.
#func _ready():
##	modulate = HVR_COLOURS[0]
#
#	draw_from_data(
#		card_data
#	)



func draw_from_data(cDat: Dictionary) -> void:
	draw_stats(cDat)
	draw_sigils(cDat)
	draw_costs(cDat)
	draw_conduit(cDat)
	draw_active(cDat)


func draw_stats(cDat: Dictionary) -> void:
	$CardPort.texture = load("res://gfx/pixport/" + cDat.name + ".png")
	$AtkScore.text = str(cDat.stats[0])
	$HpScore.text = str(cDat.stats[1])

func draw_sigils(cDat: Dictionary) -> void:
	
	var sCount = len(cDat.get("sigils", []))
	
	# Clear, in case it needs to happen again
	for sigSlt in SIGIL_SLOTS:
		get_node(sigSlt).hide()
	
	# Fix spacing	
	$Sigils/Row2.visible = (sCount > 3)
	
	# Special case: Don't draw sigils if an active sigil is present
	if "active" in cDat.get("traits", []) or sCount == 0:
		return
	
	for sIdx in range(sCount):
		var cNode = get_node(SIGIL_SLOTS[sIdx])
		cNode.texture = load("res://gfx/sigils/%s.png" % cDat.sigils[sIdx])
		cNode.show()


# This could potentially be called multiple times on the same card,
# e.g. when evolving. Therefore costs need to be manually hidden
# when not in use
func draw_costs(cDat: Dictionary) -> void:
	for cost in [
		"blood",
		"bone",
		"energy"
	]:
		var costNode = get_node("Costs/" + cost)
		var costs = cDat.get("costs", {})
		
		if not costs.get(cost):
			costNode.hide()
		else:
			var costValue = costs.get(cost)
			
			costNode.show()
			
			for node in costNode.get_children():
				node.hide()
			
			if costValue < 3:
				costNode.get_node(str(costValue)).show()
				
			else:
				costNode.get_node("TXIcon").show()
				var txtParent = costNode.get_node("Text")
				txtParent.show()
				var txtNodes = txtParent.get_children()
				for txt in txtNodes:
					txt.text = "x" + str(costValue)
				costNode.get_node("Text").rect_min_size.x = 39 + (18 * floor(log(costValue) / log(10)))


# Conduit sigil
func draw_conduit(cDat: Dictionary) -> void:
	$Sigils/ConduitIndicator.visible = "conduit" in cDat.get("traits", [])

func draw_active(cDat: Dictionary) -> void:
	if "active" in cDat.get("traits", []) and cDat.get("sigils"):
		$Active.show()
		$Active/ActiveIcon.texture = load("res://gfx/sigils/" + cDat.sigils[0] + ".png")
	else:
		$Active.hide()

# Hover, click handlers
func _on_CardBtn_button_down() -> void:
	modulate = HVR_COLOURS[2]

func _on_CardBtn_button_up() -> void:
	if modulate == HVR_COLOURS[2]:
		modulate = HVR_COLOURS[1]
		

func _on_CardBtn_mouse_entered() -> void:
	if modulate == HVR_COLOURS[0]:
		modulate = HVR_COLOURS[1]


func _on_CardBtn_mouse_exited() -> void:
	modulate = HVR_COLOURS[0]


func _on_Active2_mouse_entered() -> void:
	if modulate == HVR_COLOURS[0]:
		modulate = HVR_COLOURS[1]

func _on_Active2_mouse_exited() -> void:
	modulate = HVR_COLOURS[0]


func _on_Active2_button_down() -> void:
	$Active/ActiveIcon.rect_position = Vector2(6, 16)


func _on_Active2_button_up() -> void:
	$Active/ActiveIcon.rect_position = Vector2(6, 6)

