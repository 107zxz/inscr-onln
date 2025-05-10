extends SigilEffect

#Used for sigils that do something after a card attacks one or more times
func after_attacks(card_anim, had_any_successful_attacks: bool):
	if had_any_successful_attacks:
		card_anim.play("Perish")
