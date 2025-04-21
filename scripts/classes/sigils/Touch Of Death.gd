extends SigilEffect

#Used for sigils that do something when damaging another card, although this can still be done with 'handle_event'
func on_damage_card(card_hit, damage: int):
	if not card_hit.has_sigil("Made of Stone") and not damage == FULLY_NEGATED_DAMAGE_VAL:
		card_hit.get_node("AnimationPlayer").play("Perish")
