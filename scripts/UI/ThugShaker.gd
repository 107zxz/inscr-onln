extends Label

const BASE_POS = Vector2(730, 465)
const THUG_STR = 7

func appear(days):
	if days > 0:
		text = "god is coming\nin %d days" % days
	else:
		text = "god is here"
	show()
	$WarningTimer.start()

func _process(delta):
	if visible:
		rect_position = BASE_POS + Vector2(
			rand_range(-THUG_STR, THUG_STR),
			rand_range(-THUG_STR, THUG_STR)
		)

func _on_WarningTimer_timeout():
	hide()
