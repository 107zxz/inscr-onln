extends SigilEffect

func stat_modifying_aura(card_being_updated, friendly_to_sigilholder: bool):
	if friendly_to_sigilholder and abs(card_being_updated.slot_idx() - card.slot_idx()) == 1:
		card_being_updated.attack+=1
