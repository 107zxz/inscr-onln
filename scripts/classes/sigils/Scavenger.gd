extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	if event == "card_perished" and not card.inHand and (params[0].get_parent().get_parent().name == "PlayerSlots") != isFriendly:
		if not params[0].has_sigil("Boneless"):
			if isFriendly:
				if params[0].has_sigil("Bone King"):
					fightManager.add_bones(4)
					if fightManager.opponent_bones >= 0:
						fightManager.add_opponent_bones(-4)
				else: 
					fightManager.add_bones(1)
				if fightManager.opponent_bones >= 0:
					fightManager.add_opponent_bones(-1)
			else:
				if params[0].has_sigil("Bone King"):
					fightManager.add_opponent_bones(4)
					if fightManager.bones >= 0: 
						fightManager.add_bones(-4)
				else:
					fightManager.add_opponent_bones(1)
					if fightManager.bones >= 0:
						fightManager.add_bones(-1)
