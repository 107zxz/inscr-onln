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

var card_data = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	modulate = HVR_COLOURS[0]
	
	draw_from_data(
		{
			"sigils": [
				"Airborne",
				"Mighty Leap",
				"Burrower",
				"Omni Strike",
				"Armored",
				"Armored",
			]
		}
	)



func draw_from_data(cDat: Dictionary):
	
	var sCount = len(cDat.sigils)
	
	for sIdx in range(sCount):
		var cNode = get_node(SIGIL_SLOTS[sIdx])
		cNode.texture = load("res://gfx/sigils/%s.png" % cDat.sigils[sIdx])
		cNode.show()


func _on_CardBtn_button_down():
	modulate = HVR_COLOURS[2]

func _on_CardBtn_button_up():
	if modulate == HVR_COLOURS[2]:
		modulate = HVR_COLOURS[1]
		

func _on_CardBtn_mouse_entered():
	if modulate == HVR_COLOURS[0]:
		modulate = HVR_COLOURS[1]


func _on_CardBtn_mouse_exited():
	modulate = HVR_COLOURS[0]


func _on_Active2_mouse_entered():
	if modulate == HVR_COLOURS[0]:
		modulate = HVR_COLOURS[1]

func _on_Active2_mouse_exited():
	modulate = HVR_COLOURS[0]


func _on_Active2_button_down():
	$Active2/ActiveIcon.rect_position = Vector2(6, 16)


func _on_Active2_button_up():
	$Active2/ActiveIcon.rect_position = Vector2(6, 6)



