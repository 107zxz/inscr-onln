extends Control


onready var litTex = $Candle1.texture.duplicate()
onready var exTex = $Candle2.texture.duplicate()


func set_lives(lives):
	if lives == 2:
		$Candle2.texture = litTex
	else:
		$Candle2.texture = exTex
	
	if lives >= 1:
		$Candle1.texture = litTex
	else:
		$Candle1.texture = exTex
