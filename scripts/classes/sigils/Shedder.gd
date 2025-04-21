extends "res://scripts/classes/sigils/Sprinter.gd"

func on_move(curSlot):
	slotManager.summon_card(CardInfo.from_name(card.card_data.sheds), curSlot, isFriendly)
