extends SigilEffect

#Used for sigils that passively modify the stats of *other* cards.
func stat_modifying_aura(card_being_updated, friendly_to_sigilholder: bool):
	if friendly_to_sigilholder and "mox" in card_being_updated.card_data["name"].to_lower(): #if tribes are added and moxen are a tribe, this can be changed
		card_being_updated.attack+=1
