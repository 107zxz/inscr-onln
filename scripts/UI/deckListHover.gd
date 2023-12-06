extends Button

func hover():
	$"../../../../../Card".draw_from_data(CardInfo.from_name(text))

func _ready():
	connect("mouse_entered", self, "hover")
