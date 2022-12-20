extends Label

func _ready():
	connect("mouse_entered", self, "_mouse_entered")
	connect("mouse_exited", self, "_mouse_exited")

func _mouse_entered():
	add_color_override("font_color", Color.white)

func _mouse_exited():
	remove_color_override("font_color")

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		get_node("..").passage_clicked(text.substr(3))
