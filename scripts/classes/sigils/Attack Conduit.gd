extends SigilEffect

#Used for sigils that passively modify the stats of *other* cards.
func stat_modifying_aura(card_being_updated, friendly_to_sigilholder: bool):
	if card_being_updated == card or not friendly_to_sigilholder:
		return
	var index = card_being_updated.slot_idx()
	var conduit_data = slotManager.friendly_conduit_data if is_friendly else slotManager.enemy_conduit_data
	if index > conduit_data[0] and index < conduit_data[1]:
		card_being_updated.attack+=1
