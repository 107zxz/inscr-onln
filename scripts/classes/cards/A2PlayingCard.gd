extends "res://scripts/classes/cards/A2Card_Compat.gd"


# Clicked
func _on_CardBtn_button_down() -> void:
	._on_CardBtn_button_down()
	print("Clicked")

# Active sigil btn
func _on_Active_button_up() -> void:
	._on_Active2_button_up()
	print("Activated")

