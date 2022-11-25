extends PanelContainer


func update_options():
	for cat in $TabContainer.get_children():
		for opt in cat.get_children():
			if opt.name in GameOptions.options:
				
				var old_val = GameOptions.options[opt.name]
				
				GameOptions.options[opt.name] = not opt.pressed
				
				# Reload deck editor
				if old_val == opt.pressed and opt.name in ["enable_accessibility_icons", "show_card_tooltips", "show_banned"]:
					get_node("/root/Main/DeckEdit").search()
				
				# Stretch screen
				if old_val == opt.pressed and opt.name == "stretch_to_fill":
			#		get_viewport().size = OS.window_size
					if GameOptions.options.stretch_to_fill:
						get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_VIEWPORT, SceneTree.STRETCH_ASPECT_IGNORE, Vector2(1920, 1080))
					else:
						get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_VIEWPORT, SceneTree.STRETCH_ASPECT_KEEP, Vector2(1920, 1080))
					
				if old_val == opt.pressed and opt.name == "fullscreen":
					OS.window_fullscreen = GameOptions.options.fullscreen
				
				if old_val == opt.pressed and opt.name == "crt_filter":
					get_node("/root/Main/Scanlines").visible = GameOptions.options.crt_filter

				if old_val == opt.pressed and opt.name == "enable_sfx":
					AudioServer.set_bus_mute(2, not GameOptions.options.enable_sfx)
				if old_val == opt.pressed and opt.name == "enable_music":
					AudioServer.set_bus_mute(1, not GameOptions.options.enable_music)
				
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
	
	# Apply options
	get_node("/root/Main/Scanlines").visible = GameOptions.options.crt_filter
	AudioServer.set_bus_mute(1, not GameOptions.options.enable_music)
	AudioServer.set_bus_mute(2, not GameOptions.options.enable_sfx)
	
	
