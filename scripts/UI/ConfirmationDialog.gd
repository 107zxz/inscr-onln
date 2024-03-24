extends Panel


signal option_picked(option)


var current_url = ""


func _ready():
	for button in $PanelContainer/VBoxContainer/HBoxContainer.get_children():
		
		if button.name == "SourceBtn":
			continue
		
		button.connect("pressed", self, "click_option", [button.text])
		
		
func click_option(option: String):
	emit_signal("option_picked", option)
	hide()


func view_source():
	OS.shell_open(current_url)
