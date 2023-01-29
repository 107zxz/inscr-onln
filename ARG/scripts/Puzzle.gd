extends Control

var progress = 0

func _on_Piece1_pressed():
	if progress == 0:
		$AnimationPlayer.play("Piece1")
		progress = 1

func _on_Piece2_pressed():
	if progress == 1:
		$AnimationPlayer.play("Piece2")
		progress = 2

func _on_Piece3_pressed():
	if progress == 2:
		$AnimationPlayer.play("Piece3")
		progress = 3

func _on_Piece4_pressed():
	if progress == 3:
		$AnimationPlayer.play("Piece4")
		progress = 4

func _on_Piece5_pressed():
	if progress == 4:
		$AnimationPlayer.play("Piece5")
		progress = 4
