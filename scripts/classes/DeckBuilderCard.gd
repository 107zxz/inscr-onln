extends Control

onready var deckContainer = get_node("/root/Main/DeckEdit/HBoxContainer/VBoxContainer/MainArea/VBoxContainer/DeckPreview/DeckContainer")
onready var previewCont = get_node("/root/Main/DeckEdit/HBoxContainer/CardPreview/PreviewContainer/")


onready var sigilDescPrefab = preload("res://packed/SigilDescription.tscn")
onready var allCardData = get_node("/root/Main/AllCards")

var card_data = {}

func from_data(cdat):
	card_data = cdat
	
	$VBoxContainer/Label.text = card_data.name
	$VBoxContainer/Portrait.texture = load("res://gfx/pixport/" + card_data.name + ".png")
	
	# Rare
	if "rare" in card_data:
		var sbox = $Button.get_stylebox("normal").duplicate()
		var sboxH = $Button.get_stylebox("hover").duplicate()
		if "nosac" in card_data:
			sbox.bg_color = Color("ad9551")
			sboxH.bg_color = Color("c2af7c")
		else:
			sbox.bg_color = Color("ceb46d")
			sboxH.bg_color = Color("dfc98e")
		$Button.add_stylebox_override("normal", sbox)
		$Button.add_stylebox_override("hover", sboxH)
	elif "nosac" in card_data:
		var sbox = $Button.get_stylebox("normal").duplicate()
		var sboxH = $Button.get_stylebox("hover").duplicate()
		sbox.bg_color = Color("969275")
		sboxH.bg_color = Color("b0ab89")
		$Button.add_stylebox_override("normal", sbox)
		$Button.add_stylebox_override("hover", sboxH)
	else:
		$Button.add_stylebox_override("normal", null)
		$Button.add_stylebox_override("hover", null)
	
	# Update card costs and sigils
	draw_cost()
	draw_sigils()

func draw_cost():
	if card_data["blood_cost"] > 0:
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
	
	if card_data["bone_cost"] > 0:
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
	else:
		$VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BoneCost.visible = false
		
	if card_data["energy_cost"] > 0:
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
	if card_data["mox_cost"]:
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

func draw_sigils():
	# Sigils
	if len(card_data.sigils) > 0:
		if "active" in card_data:
			$VBoxContainer/HBoxContainer/ActiveSigil.visible = true
			$VBoxContainer/HBoxContainer/ActiveSigil.icon = load("res://gfx/sigils/" + card_data.sigils[0] + ".png")
			$VBoxContainer/HBoxContainer/Sigil.visible = false
		else:
			$VBoxContainer/HBoxContainer/Sigil.texture = load("res://gfx/sigils/" + card_data.sigils[0] + ".png")
			$VBoxContainer/HBoxContainer/Sigil.visible = true
			$VBoxContainer/HBoxContainer/ActiveSigil.visible = false
		
		if len(card_data.sigils) > 1:
			$VBoxContainer/HBoxContainer/Sigil2.visible = true
			$VBoxContainer/HBoxContainer/Spacer3.visible = true
			$VBoxContainer/HBoxContainer/Sigil2.texture = load("res://gfx/sigils/" + card_data.sigils[1] + ".png")
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


func _on_Button_pressed():
	# Am I in the search window? If so, add me to the deck if space provides
	if get_parent().name == "SearchContainer":
		if "rare" in card_data:
			if get_node("/root/Main/DeckEdit").get_card_count(card_data) != 0:
				return
		else:
			if get_node("/root/Main/DeckEdit").get_card_count(card_data) >= 4:
				return
		var newCard = self.duplicate(7)
		newCard.from_data(card_data)
		deckContainer.add_child(newCard)
		get_node("/root/Main/DeckEdit").update_deck_count(1)
		
	
	# Am I in the deck window? If so, delete me
	if get_parent().name == "DeckContainer":
		get_node("/root/Main/DeckEdit").update_deck_count(-1)
		
		queue_free()
	
	# Am I in the mox container? If so, cycle me
	if get_parent().name == "MoxContainer":
		var currIdx = allCardData.all_cards.find(card_data)
		var nextIdx = (currIdx - 96) % 3 + 97
		
		from_data(allCardData.all_cards[nextIdx])
	


func _on_Card_mouse_entered():
	if not card_data:
		return
	
	previewCont.get_child(0).from_data(card_data)
	
	# Display sigils
	var sigIdx = 0
	
	for sigdisp in previewCont.get_child(1).get_children():
		sigdisp.visible = false
	
	for sigdat in card_data.sigils:
#		var sd = sigilDescPrefab.instance()
		var sd = previewCont.get_child(1).get_child(sigIdx)
		sd.get_child(1).texture = load("res://gfx/sigils/" + sigdat + ".png")
		sd.get_child(2).text = allCardData.all_sigils[sigdat]

		if not sigdat in allCardData.working_sigils:
			sd.get_child(2).text += "\nThis sigil is not yet implemented, and will not work"
			sd.get_child(2).add_color_override("font_color", Color.darkred)
		else:
			sd.get_child(2).add_color_override("font_color", Color.black)

#		previewCont.get_child(1).add_child(sd)
		sd.visible = true
		sigIdx += 1

