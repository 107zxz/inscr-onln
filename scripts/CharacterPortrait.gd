extends Panel

func draw(charname:String):
	$PortraitDisp.texture = load("res://gfx/char_portraits/"+charname+".png")
