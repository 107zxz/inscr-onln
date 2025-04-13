extends SigilEffect

#Used for sigils that do something after a card successfully attacks one or more times
func after_successful_attacks(cardAnim):
	cardAnim.play("Perish")
