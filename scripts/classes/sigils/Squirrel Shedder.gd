extends "res://scripts/classes/sigils/Sprinter.gd"

#sprinter-derivitive specific function. Does something in the slot the sprinter moved FROM
func on_move(curSlot):
	slotManager.summon_card(CardInfo.from_name("Squirrel"), curSlot, isFriendly)
