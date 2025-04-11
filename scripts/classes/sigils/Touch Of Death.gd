extends SigilEffect

# This is called whenever the card with this sigil attacks, and modifies which lanes it attacks in
func on_deal_damage(card_hit, damage: int):
	if not card_hit.has_sigil("Made of Stone") and not damage == FULLY_NEGATED_DAMAGE_VAL:
		card_hit.get_node("AnimationPlayer").play("Perish")
