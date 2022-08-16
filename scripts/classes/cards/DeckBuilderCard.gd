extends "res://scripts/classes/cards/DrawCard.gd"

onready var deckContainer = get_node("/root/Main/DeckEdit/HBoxContainer/VBoxContainer/MainArea/VBoxContainer/DeckPreview/DeckContainer")
onready var previewCont = get_node("/root/Main/DeckEdit/HBoxContainer/CardPreview/PreviewContainer/")

onready var sigilDescPrefab = preload("res://packed/SigilDescription.tscn")


func from_data(cdat):
	draw_from_data(cdat)

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

		var startIdx = CardInfo.all_cards.find(CardInfo.from_name("Emerald Mox"))

		var currIdx = CardInfo.all_cards.find(card_data)
		var nextIdx = (currIdx - startIdx + 1) % 3 + startIdx
		from_data(CardInfo.all_cards[nextIdx])
		_on_Card_mouse_entered()

	# Am I the editable empty vessel?
	if name == "SDCardSingle":

		var startIdx = CardInfo.all_cards.find(CardInfo.from_name("Empty Vessel"))
		var endIdx = CardInfo.all_cards.find(CardInfo.from_name("Contaminated Vessel"))

		var currIdx = CardInfo.all_cards.find(card_data)

		print("Startidx: ", startIdx, " Endidx: ", endIdx, " Curridx: ", currIdx)

		if currIdx > startIdx - 1 and currIdx < endIdx + 1:
			var nextIdx = (currIdx - startIdx + 1) % (endIdx - startIdx + 1) + startIdx
			from_data(CardInfo.all_cards[nextIdx])
			previewCont.get_child(0).from_data(card_data)
			_on_Card_mouse_entered()



func _on_Card_mouse_entered():
	if not card_data:
		return

	previewCont.get_child(0).from_data(card_data)



	# Display sigils
	var sigIdx = 1

	for sigdisp in previewCont.get_child(1).get_children():
		sigdisp.visible = false

	# Display description
	if "description" in card_data:
		var cDesc = previewCont.get_child(1).get_child(0)
		cDesc.visible = true
		cDesc.text = card_data["description"]

	if not "sigils" in card_data:
		return

	for sigdat in card_data.sigils:
#		var sd = sigilDescPrefab.instance()
		var sd = previewCont.get_child(1).get_child(sigIdx)
		sd.get_child(1).texture = load("res://gfx/sigils/" + sigdat + ".png")
		sd.get_child(2).text = sigdat + ":\n" + CardInfo.all_sigils[sigdat]

		if not sigdat in CardInfo.working_sigils:
			sd.get_child(2).text += "\nThis sigil is not yet implemented, and will not work"
			sd.get_child(2).add_color_override("font_color", Color.darkred)
		else:
			sd.get_child(2).add_color_override("font_color", paperTheme.get_color("font_color", "Label"))

#		previewCont.get_child(1).add_child(sd)
		sd.visible = true
		sigIdx += 1
