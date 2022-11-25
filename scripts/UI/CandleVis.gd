extends Control


onready var litTex = $Candle1.texture.duplicate()
onready var exTex = $Candle2.texture.duplicate()

export (int) var three_bump = 0

func set_lives(lives):
	if lives >= 3:
		$Candle3.texture = litTex
	else:
		$Candle3.texture = exTex
		
	if lives >= 2:
		$Candle2.texture = litTex
	else:
		$Candle2.texture = exTex
	
	if lives >= 1:
		$Candle1.texture = litTex
	else:
		$Candle1.texture = exTex

func _ready():
	if CardInfo.all_data.num_candles == 3:
		$Candle3.visible = true
		$Base2.visible = true
		
		rect_position.x += three_bump
		
