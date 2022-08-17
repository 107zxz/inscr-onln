extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, _params: Array):

    # attached_card_summoned represents the card bearing the sigil being summoned
    if event == "attached_card_summoned":
        var old_data = card.card_data.duplicate()

        old_data.erase("sigils")

        # Draw the modified card copy
        fightManager.draw_card(old_data)