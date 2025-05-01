extends SigilEffect

func start_of_turn(cardAnim):
	Gem_Dep()
	
# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if (event == "card_summoned" and params[0] == card and not card.in_hand) or (event == "card_perished" and params[0] != card and not card.in_hand and not "vanilla_gem_dep" in CardInfo.all_data):
			Gem_Dep()

func end_of_turn(cardAnim):
	Gem_Dep()
	
func Gem_Dep():
	if not "Perish" in card.get_node("AnimationPlayer").current_animation:

			var kill = not (slotManager.get_friendly_cards_sigil("Great Mox") if isFriendly else slotManager.get_enemy_cards_sigil("Great Mox"))

			for moxcol in ["Green", "Blue", "Orange"]:
				for foundMox in (slotManager.get_friendly_cards_sigil(moxcol + " Mox") if isFriendly else slotManager.get_enemy_cards_sigil(moxcol + " Mox")):
					if foundMox != self:
						kill = false;
						break
			
			if kill:
				print("Gem dependant card should die!")
				card.get_node("AnimationPlayer").play("Perish")
