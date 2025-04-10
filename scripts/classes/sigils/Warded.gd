extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_summoned" and params[0] == card:
		card.get_node("CardBody/Highlight").visible = true

func modify_damage_taken(dmg_amt: int):
	return clamp(dmg_amt, dmg_amt, 1)
