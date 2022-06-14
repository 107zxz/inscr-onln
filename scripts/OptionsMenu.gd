extends PanelContainer

var paperTheme = preload("res://themes/papertheme.tres")

func _on_SaveButton_pressed():
	# Background Color
	paperTheme.get_stylebox("panel", "Panel").bg_color = Color.red
	paperTheme.get_stylebox("panel", "Panel").border_color = Color.aquamarine
	paperTheme.get_stylebox("panel", "PanelContainer").bg_color = Color.blue
	paperTheme.get_stylebox("normal", "Card").bg_color = Color.green
	paperTheme.get_stylebox("rare_normal", "Card").bg_color = Color.orange
	paperTheme.get_stylebox("rns_normal", "Card").bg_color = Color.brown
	paperTheme.get_stylebox("nosac_normal", "Card").bg_color = Color.crimson
	paperTheme.get_stylebox("normal", "LineEdit").bg_color = Color.pink
	paperTheme.get_stylebox("normal", "Button").bg_color = Color.lightblue
	
	# Button colours
	for col in paperTheme.get_color_list("Button"):
		paperTheme.set_color(col, "Button", Color.white)
	
	paperTheme.set_color("font_color", "Label", Color.white)
	
	VisualServer.set_default_clear_color(Color.purple)
