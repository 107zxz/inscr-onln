extends HBoxContainer

func from_data(chardata:Dictionary, charname:String):
	$PortraitFrame.draw(charname)
	$DescriptionContainer/Title.text = charname
	
	if "desc" in chardata:
		$DescriptionContainer/Description.text = chardata.desc
	else:
		$DescriptionContainer/Description.text = "This character has no description."
	
