extends Control

var can_interact = true
var raisedCard = null

func _ruleset_card_clicked(rCard):
	for card in $Rulesets.get_children():
		if card != rCard:
			card.lower()
		
	raisedCard = null if rCard.raised else rCard

func _select_slot_clicked():
	if not raisedCard:
		return
	
	raisedCard.lower()
	yield(get_tree().create_tween().tween_property(raisedCard, "rect_global_position", $RulesetSlot.rect_global_position, 0.1), "finished")
	
	$PickerBlocker.visible = true
