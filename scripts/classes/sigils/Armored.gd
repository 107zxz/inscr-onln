extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_summoned" and params[0] == card:
		card.get_node("CardBody/Highlight").visible = true

# This is called whenever the card with this sigil takes damage, and modifies the damage taken
func modify_damage_taken(dmg_amt: int):
	if card.get_node("CardBody/Highlight").visible:
		card.get_node("CardBody/Highlight").visible = false
		return FULLY_NEGATED_DAMAGE_VAL
	return dmg_amt
