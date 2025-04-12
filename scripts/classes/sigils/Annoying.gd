extends SigilEffect


func stat_modifying_aura(card_being_updated, friendly_to_sigilholder: bool):
	if not friendly_to_sigilholder and card_being_updated.slot_idx() == card.slot_idx() and not card_being_updated.has_sigil("Made of Stone"):
		card_being_updated.attack += 1
