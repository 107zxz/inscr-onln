extends PanelContainer

func update_options():
	for cat in $TabContainer.get_children():
		for opt in cat.get_children():
			if opt.name in GameOptions.options:
				
				var old_val = GameOptions.options[opt.name]
				
				GameOptions.options[opt.name] = not opt.pressed
				
				# Reload deck editor
				if old_val == opt.pressed and opt.name in ["enable_accessibility_icons", "show_card_tooltips"]:
					get_node("/root/Main/DeckEdit").search()

func update_controls():
	for cat in $TabContainer.get_children():
		for opt in cat.get_children():
			if opt.name in GameOptions.options:
				opt.pressed = not GameOptions.options[opt.name]

func connect_signals():
	for cat in $TabContainer.get_children():
		for opt in cat.get_children():
			if opt.name in GameOptions.options:
				opt.connect("pressed", self, "update_options")

func _ready():
	
	update_controls()
	connect_signals()
