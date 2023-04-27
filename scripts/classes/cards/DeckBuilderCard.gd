extends "res://scripts/classes/cards/A2Card_Compat.gd"

onready var deckContainer = get_node("/root/Main/DeckEdit/HBoxContainer/VBoxContainer/MainArea/VBoxContainer/DeckPreview/DeckContainer")
onready var sideDeckContainer = get_node("/root/Main/DeckEdit/HBoxContainer/VBoxContainer/MainArea/VBoxContainer/DeckPreview2/TabContainer/Side Deck Draft/SideDeckContainer")
onready var previewCont = get_node("/root/Main/DeckEdit/HBoxContainer/CardPreview/PreviewContainer/")

onready var sigilDescPrefab = preload("res://packed/SigilDescription.tscn")

onready var deckEditor = get_node("/root/Main/DeckEdit")

func from_data(cdat):
	card_data = cdat
	draw_from_data(cdat)
	
func _on_Button_pressed():
	
	# Don't allow interaction i banned
	if $BannedOverlay.visible:
		return
	
	# Am I in the search window? If so, add me to the deck if space provides
	if get_parent().name == "SearchContainer":
		
		if deckEditor.tab_cont.current_tab == 1:
			if "rare" in card_data:
				if deckEditor.get_sd_card_count(card_data) != 0:
					return

			else:
				if deckEditor.get_sd_card_count(card_data) >= CardInfo.all_data.max_commons_side:
					return

			if sideDeckContainer.get_child_count() >= CardInfo.side_decks[CardInfo.side_decks.keys()[deckEditor.sidedeck_de.selected]].count:
				return
			var newCard = self.duplicate(7)
			newCard.from_data(card_data)
			sideDeckContainer.add_child(newCard)
			newCard.modulate = HVR_COLOURS[0]
#			deckEditor.update_deck_count(1)
		else:
			if "rare" in card_data:
				if deckEditor.get_card_count(card_data) != 0:
					return
			else:
				if deckEditor.get_card_count(card_data) >= CardInfo.all_data.max_commons_main:
					return
			var newCard = self.duplicate(7)
			newCard.from_data(card_data)
			deckContainer.add_child(newCard)
			newCard.modulate = HVR_COLOURS[0]
			deckEditor.update_deck_count(1)


	# Am I in the deck window? If so, delete me
	if "DeckContainer" in get_parent().name:
		if not "Side" in get_parent().name:
			deckEditor.update_deck_count(-1)
		queue_free()

	# Am I in the mox container? If so, cycle me
#	if get_parent().name == "MoxContainer":
#
#		var startIdx = CardInfo.all_cards.find(CardInfo.from_name("Emerald Mox"))
#
#		var currIdx = CardInfo.all_cards.find(card_data)
#		var nextIdx = (currIdx - startIdx + 1) % 3 + startIdx
#		from_data(CardInfo.all_cards[nextIdx])
#		_on_Card_mouse_entered()
	

func _on_Card_mouse_entered():
	if not card_data:
		return

	previewCont.get_child(0).from_data(card_data)


	# Display sigils
	var sigIdx = 0

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
		var sd = previewCont.get_child(1).get_child(sigIdx + 1)


		# Steal texture from card
		if "active" in card_data:
			sd.get_child(1).texture = $Active/ActiveIcon.texture
		else:
			sd.get_child(1).texture = $Sigils/Row1.get_child(sigIdx).texture

		sd.get_child(2).text = sigdat + ":\n" + CardInfo.all_sigils[sigdat]

		if not sigdat in CardInfo.working_sigils:
			sd.get_child(2).text += "\nThis sigil is not yet implemented, and will not work"
			sd.get_child(2).add_color_override("font_color", Color.darkred)
		else:
			sd.get_child(2).add_color_override("font_color", paperTheme.get_color("font_color", "Label"))

#		previewCont.get_child(1).add_child(sd)
		sd.visible = true
		sigIdx += 1
