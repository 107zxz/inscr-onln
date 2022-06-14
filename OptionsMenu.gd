extends PanelContainer

var paperTheme = preload("res://themes/papertheme.tres")

func _on_SaveButton_pressed():
	# Background Color
	paperTheme.get_stylebox("panel", "Panel").bg_color = Color.red
	paperTheme.get_stylebox("panel", "PanelContainer").bg_color = Color.blue
	paperTheme.get_stylebox("normal", "Card").bg_color = Color.green
	paperTheme.get_stylebox("rare_normal", "Card").bg_color = Color.orange
	paperTheme.get_stylebox("rns_normal", "Card").bg_color = Color.brown
	paperTheme.get_stylebox("nosac_normal", "Card").bg_color = Color.gray
	paperTheme.get_stylebox("normal", "LineEdit").bg_color = Color.pink
	paperTheme.get_stylebox("normal", "Button").bg_color = Color.lightblue
	
	VisualServer.set_default_clear_color(Color.purple)
