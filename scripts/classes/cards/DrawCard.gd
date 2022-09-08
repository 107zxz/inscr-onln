extends PanelContainer

var card_data = {}

var paperTheme = preload("res://themes/papertheme.tres")

func draw_from_data(cdat):
	card_data = cdat

	$VBoxContainer/Label.text = card_data.name
	
	# Special portrait overrides
	var d = Directory.new()
	if d.file_exists(CardInfo.portrait_override_path + card_data.name + ".png"):
		var i = Image.new()
		i.load(CardInfo.portrait_override_path + card_data.name + ".png")
		var tx = ImageTexture.new()
		tx.create_from_image(i)
		tx.flags -= tx.FLAG_FILTER
		$VBoxContainer/Portrait.texture = tx
	elif "pixport_url" in card_data:
		var i = Image.new()
		i.load(CardInfo.custom_portrait_path + card_data.name + ".png")
		var tx = ImageTexture.new()
		tx.create_from_image(i)
		tx.flags -= tx.FLAG_FILTER
		$VBoxContainer/Portrait.texture = tx
	else:
		$VBoxContainer/Portrait.texture = load("res://gfx/pixport/" + card_data.name + ".png")
	
	# Rare
	if "rare" in card_data:
		if "nosac" in card_data:
			for btn in [$Button, $VBoxContainer/HBoxContainer/ActiveSigil]:
				btn.add_stylebox_override("normal", paperTheme.get_stylebox("rns_normal", "Card"))
				btn.add_stylebox_override("hover", paperTheme.get_stylebox("rns_hover", "Card"))
		elif "nohammer" in card_data:
			for btn in [$Button, $VBoxContainer/HBoxContainer/ActiveSigil]:
				btn.add_stylebox_override("normal", paperTheme.get_stylebox("nohammer_normal", "Card"))
				btn.add_stylebox_override("hover", paperTheme.get_stylebox("nohammer_hover", "Card"))
		else:
			for btn in [$Button, $VBoxContainer/HBoxContainer/ActiveSigil]:
				btn.add_stylebox_override("normal", paperTheme.get_stylebox("rare_normal", "Card"))
				btn.add_stylebox_override("hover", paperTheme.get_stylebox("rare_hover", "Card"))
	elif "nosac" in card_data:
		for btn in [$Button, $VBoxContainer/HBoxContainer/ActiveSigil]:
			btn.add_stylebox_override("normal", paperTheme.get_stylebox("nosac_normal", "Card"))
			btn.add_stylebox_override("hover", paperTheme.get_stylebox("nosac_hover", "Card"))
	elif "nohammer" in card_data:
		for btn in [$Button, $VBoxContainer/HBoxContainer/ActiveSigil]:
			btn.add_stylebox_override("normal", paperTheme.get_stylebox("nohammer_normal", "Card"))
			btn.add_stylebox_override("hover", paperTheme.get_stylebox("nohammer_hover", "Card"))
	else:
		for btn in [$Button, $VBoxContainer/HBoxContainer/ActiveSigil]:
			btn.add_stylebox_override("normal", paperTheme.get_stylebox("normal", "Card"))
			btn.add_stylebox_override("hover", paperTheme.get_stylebox("hover", "Card"))
	
	# Conduit
	$VBoxContainer/ConduitIcon.visible = "conduit" in card_data

	# Update card costs and sigils
	draw_cost()
	draw_sigils()

	# Special attack values, etc
	draw_special()

func draw_special():
	if "sigils" in card_data and "Tentacle" in card_data["sigils"] and has_node("DiveOlay"):
		$DiveOlay.texture = load("res://gfx/sigils/Tentacle.png")
	if "atkspecial" in card_data:

		$AtkIcon.texture = $AtkIcon.texture.duplicate()
		
		match card_data.atkspecial:
			0.0:
				$AtkIcon.texture.region = Rect2(0, 0, 16, 8)
			1.0:
				$AtkIcon.texture.region = Rect2(0, 27, 16, 8)
			2.0:
				$AtkIcon.texture.region = Rect2(0, 9, 16, 8)

		$AtkIcon.visible = true
		$HBoxContainer/AtkScore.visible = false
	else:
		$AtkIcon.visible = false
		$HBoxContainer/AtkScore.visible = true
	
	# Tooltip
	$Button.hint_tooltip = ""
	
	if GameOptions.options.show_card_tooltips:
		$Button.hint_tooltip = card_data.name + "\nPower: " + str(card_data.attack) + "\nHealth: " + str(card_data.health) + "\n"
		
		if "rare" in card_data:
			$Button.hint_tooltip += "Rare: You may only use one copy of this card in your deck.\n"
			
		if "nosac" in card_data:
			$Button.hint_tooltip += "Terrain: This card cannot be sacrificed.\n"
		
		if "nohammer" in card_data:
			$Button.hint_tooltip += "Unhammerable: This card cannot be hammered.\n"
		
		if "conduit" in card_data:
			$Button.hint_tooltip += "Conduit: This card completes a circuit. At least 2 circuit completing \ncards are needed to complete a circuit.\n"
		
		if "sigils" in card_data:
			for sigil in card_data.sigils:
				var target_text = "\n" + sigil + ": " + CardInfo.all_sigils[sigil]
				
				var charcnt = 0
				
				for word in target_text.split(" "):
					charcnt += len(word)
					$Button.hint_tooltip += word + " "
					
					if charcnt > 50:
						$Button.hint_tooltip += "\n"
						charcnt = 0
				
				# Make sure newlines don't double up on occasion
				if $Button.hint_tooltip.right(len($Button.hint_tooltip) - 1) != "\n":
					$Button.hint_tooltip += "\n"
		
		if "evolution" in card_data:
			$Button.hint_tooltip += "This card evolves into: %s\n\n" % card_data.evolution
		
		
func draw_cost():
	if "blood_cost" in card_data:
		$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BloodCost.visible = true
		$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BloodCost.texture = $VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BloodCost.texture.duplicate()
		$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BloodCost.texture.region = Rect2(
			28,
			16 * (card_data["blood_cost"] - 1) + 1,
			26,
			15
		)
	else:
		$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BloodCost.visible = false
	
	if "bone_cost" in card_data:
		$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BoneCost.visible = true
		$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BoneCost.texture = $VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BoneCost.texture.duplicate()
		$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BoneCost.texture.region = Rect2(
			1,
			16 * (card_data["bone_cost"] - 1) + 1,
			26,
			15
		)
		# Special case: horseman
		if card_data["bone_cost"] == 13:
			$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BoneCost.texture.region = Rect2(
				28,
				145,
				26,
				15
			)
		# Special case: shambling cairn
		if card_data["bone_cost"] == -1:
			$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BoneCost.texture.region = Rect2(
				28,
				97,
				26,
				15
			)
	else:
		$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BoneCost.visible = false
		
	if "energy_cost" in card_data:
		$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/EnergyCost.visible = true
		$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/EnergyCost.texture = $VBoxContainer/Portrait/HBoxContainer/VBoxContainer/EnergyCost.texture.duplicate()
		$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/EnergyCost.texture.region = Rect2(
			82,
			16 * (card_data["energy_cost"] - 1) + 1,
			26,
			15
		)
	else:
		$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/EnergyCost.visible = false
	
	# Mox cost BS
	if "mox_cost" in card_data:
		# Decide which mox to show
		var true_mox = 0
		
		var gmox = "Green" in card_data["mox_cost"]
		var omox = "Orange" in card_data["mox_cost"]
		var bmox = "Blue" in card_data["mox_cost"]
		
		true_mox = moxIdx(gmox, omox, bmox)
		
		$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/MoxCost.visible = true
		$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/MoxCost.texture = $VBoxContainer/Portrait/HBoxContainer/VBoxContainer/MoxCost.texture.duplicate()
		$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/MoxCost.texture.region = Rect2(
			55,
			16 * true_mox + 1,
			26,
			15
		)
	else:
		$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/MoxCost.visible = false
	
	# Special mods
#	$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/Special.visible = true
#	$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/Special.texture = $VBoxContainer/Portrait/HBoxContainer/VBoxContainer/Special.texture.duplicate()
#
#	if false:
	if GameOptions.options.enable_accessibility_icons:
		draw_symbols()
	else:
		$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/Special.visible = false


func draw_symbols():
	$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/Special.visible = true
	$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/Special.texture = $VBoxContainer/Portrait/HBoxContainer/VBoxContainer/Special.texture.duplicate()
	
	if "nosac" in card_data:
		$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/Special.texture.region = Rect2(
			0,
			0,
			26,
			15
		)
		pass
	elif "nohammer" in card_data:
		$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/Special.texture.region = Rect2(
			0,
			30,
			26,
			15
		)
		pass
	elif "rare" in card_data:
		$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/Special.texture.region = Rect2(
			0,
			15,
			26,
			15
		)
		pass
	else:
		$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/Special.visible = false
func draw_sigils():
		# Sigils

		var sig1 = null
		var sig2 = null
		var d = Directory.new()

		if "sigils" in card_data and len(card_data.sigils) >= 1:
			if d.file_exists(CardInfo.icon_override_path + card_data.sigils[0] + ".png"):
				var i = Image.new()
				i.load(CardInfo.icon_override_path + card_data.sigils[0] + ".png")
				sig1 = ImageTexture.new()
				sig1.create_from_image(i)
				sig1.flags -= sig1.FLAG_FILTER
			elif d.file_exists(CardInfo.custom_icon_path + card_data.sigils[0] + ".png"):
				var i = Image.new()
				i.load(CardInfo.custom_icon_path + card_data.sigils[0] + ".png")
				sig1 = ImageTexture.new()
				sig1.create_from_image(i)
				sig1.flags -= sig1.FLAG_FILTER
			else:
				sig1 = load("res://gfx/sigils/" + card_data.sigils[0] + ".png")

			if len(card_data.sigils) == 2:
				if d.file_exists(CardInfo.icon_override_path + card_data.sigils[1] + ".png"):
					var i = Image.new()
					i.load(CardInfo.icon_override_path + card_data.sigils[1] + ".png")
					sig2 = ImageTexture.new()
					sig2.create_from_image(i)
					sig2.flags -= sig1.FLAG_FILTER
				elif d.file_exists(CardInfo.custom_icon_path + card_data.sigils[1] + ".png"):
					var i = Image.new()
					i.load(CardInfo.custom_icon_path + card_data.sigils[1] + ".png")
					sig2 = ImageTexture.new()
					sig2.create_from_image(i)
					sig2.flags -= sig1.FLAG_FILTER
				else:
					sig2 = load("res://gfx/sigils/" + card_data.sigils[1] + ".png")
		
		# Minor fix
		if not "active" in card_data:
			$VBoxContainer/HBoxContainer/ActiveSigil.visible = false
		
		if "sigils" in card_data:
			if "active" in card_data:
				$VBoxContainer/HBoxContainer/ActiveSigil.visible = true
				$VBoxContainer/HBoxContainer/ActiveSigil/TextureRect.texture = sig1
				$VBoxContainer/HBoxContainer/Sigil.visible = false
				
				# Tooltip
#				$VBoxContainer/HBoxContainer/Sigil.hint_tooltip = "AMGOUS"
			else:
				$VBoxContainer/HBoxContainer/Sigil.texture = sig1
				$VBoxContainer/HBoxContainer/Sigil.visible = true
				$VBoxContainer/HBoxContainer/ActiveSigil.visible = false
			
			if len(card_data.sigils) > 1:
				$VBoxContainer/HBoxContainer/Sigil2.visible = true
				$VBoxContainer/HBoxContainer/Spacer3.visible = true
				$VBoxContainer/HBoxContainer/Sigil2.texture = sig2
			else:
				$VBoxContainer/HBoxContainer/Sigil2.texture = null
				$VBoxContainer/HBoxContainer/Sigil2.visible = false
				$VBoxContainer/HBoxContainer/Spacer3.visible = false
		else:
			$VBoxContainer/HBoxContainer/Sigil.texture = null
			$VBoxContainer/HBoxContainer/Sigil2.texture = null
			$VBoxContainer/HBoxContainer/Sigil2.visible = false
			$VBoxContainer/HBoxContainer/Spacer3.visible = false
			
		$HBoxContainer/AtkScore.text = str(card_data.attack)
		$HBoxContainer/HpScore.text = str(card_data.health)
	
# Garb
func moxIdx(gmox, omox, bmox) -> int:
	if gmox and omox and bmox:
		return 6
	if gmox and omox:
		return 5
	if omox and bmox:
		return 4
	if bmox and gmox:
		return 3
	if bmox:
		return 2
	if omox: 
		return 1
	if gmox:
		return 0
	return -1
