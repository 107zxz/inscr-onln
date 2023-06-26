extends Control



var paperTheme = preload("res://themes/papertheme.tres")

var HVR_COLOURS = [
	Color(0.933333, 0.921569, 0.843137),
	Color.white,
	Color(0.45, 0.45, 0.45)
]


const SIGIL_SLOTS = [
	"Sigils/Row1/S1",
	"Sigils/Row1/S2",
	"Sigils/Row1/S3",
	
	"Sigils/Row2/S1",
	"Sigils/Row2/S2",
	"Sigils/Row2/S3"
]

var card_data = {}

# Called when the node enters the scene tree for the first time.
func _ready():
#	modulate = HVR_COLOURS[0]
	pass


func draw_from_data(cDat: Dictionary) -> void:
	
	# Card is now face-up, hide the back
	$CardBack.hide()
	
	draw_stats(cDat)
	draw_sigils(cDat)
	draw_costs(cDat)
	draw_conduit(cDat)
	draw_active(cDat)
	draw_atkspecial(cDat)
	draw_accessibility(cDat)
	draw_tooltip(cDat)
	
	apply_theme()


func draw_tooltip(cDat):
	hint_tooltip = ""
	
	if not GameOptions.options.show_card_tooltips:
		return
		
	hint_tooltip = \
"""
%s
%d/%d
""" % [
	cDat.name,
	cDat.attack,
	cDat.health,
	]
	
	# Keywords
	for keyword in CardInfo.keywords:
		if keyword in cDat:
			hint_tooltip += wrap_string(CardInfo.keywords[keyword]) + '\n'
	
	# Add sigils
	if not "sigils" in cDat:
		return
	
	for sigil in cDat.sigils:
		hint_tooltip += \
"""
%s:
%s
""" % [sigil, wrap_string(CardInfo.all_sigils[sigil])]


func wrap_string(string_to_wrap: String) -> String:
	
	var current_char = 0
	var line_len = 0
	
	while current_char < len(string_to_wrap):
		
		if string_to_wrap[current_char] == ' ' and line_len >= 35:
			string_to_wrap[current_char] = '\n'
			line_len = 0
			
		line_len += 1
		current_char += 1
	
	return string_to_wrap

func draw_accessibility(cDat):
	
	if not GameOptions.options.enable_accessibility_icons:
		return
	
	for icon in [
		"nosac",
		"nohammer",
		"rare"
	]:
		$Costs.get_node(icon).visible = icon in cDat
		

func draw_atkspecial(cDat):
	if "atkspecial" in cDat:

		$AtkIcon.texture = $AtkIcon.texture.duplicate()
		
		match cDat.atkspecial:
			"mox", "green_mox":
				$AtkIcon.texture.region = Rect2(0, 0, 16, 8)
			"mirror":
				$AtkIcon.texture.region = Rect2(0, 27, 16, 8)
			"ant":
				$AtkIcon.texture.region = Rect2(0, 9, 16, 8)

		$AtkIcon.visible = true
		$AtkScore.visible = false
	else:
		$AtkIcon.visible = false
		$AtkScore.visible = true


func apply_theme():
#	HVR_COLOURS[0] = paperTheme.get_color("normal", "Card")
#	HVR_COLOURS[1] = paperTheme.get_color("hover", "Card")
#	HVR_COLOURS[1] = paperTheme.get_color("hover", "Card")
#	$CardBtn.modulate = paperTheme.get_stylebox("rare_normal" if "rare" in card_data else "normal", "Card").bg_color

	var th = "normal"

	if "nosac" in card_data:
		th = "nosac_normal"
	if "rare" in card_data:
		if "nosac" in card_data:
			th = "rns_normal"
		else:
			th = "rare_normal"
	if "nohammer" in card_data:
		th = "nohammer_normal"
		
	$CardBtn.modulate = paperTheme.get_stylebox(th, "Card").bg_color
	$CardBack.modulate = paperTheme.get_stylebox(th, "Card").bg_color


func draw_stats(cDat: Dictionary) -> void:
#	$CardPort.texture = load("res://gfx/pixport/" + cDat.name + ".png")
	$AtkScore.text = str(cDat.attack)
	$HpScore.text = str(cDat.health)
	
	# Special portrait overrides
	var d = Directory.new()
	if d.file_exists(CardInfo.portrait_override_path + cDat.name + ".png"):
		var i = Image.new()
		i.load(CardInfo.portrait_override_path + cDat.name + ".png")
		var tx = ImageTexture.new()
		tx.create_from_image(i)
		tx.flags -= tx.FLAG_FILTER
		$CardPort.texture = tx
	elif "pixport_url" in cDat:
		var i = Image.new()
		i.load(CardInfo.custom_portrait_path + CardInfo.ruleset + "_" + cDat.name + ".png")
		var tx = ImageTexture.new()
		tx.create_from_image(i)
		tx.flags -= tx.FLAG_FILTER
		$CardPort.texture = tx
	else:
		$CardPort.texture = load("res://gfx/pixport/" + cDat.name + ".png")

func draw_sigils(cDat: Dictionary) -> void:
	
	var sCount = len(cDat.get("sigils", []))
	
	# Clear, in case it needs to happen again
	for sigSlt in SIGIL_SLOTS:
		get_node(sigSlt).hide()
	
	# Fix spacing	
	$Sigils/Row2.visible = (sCount > 3)
	
	# Special case: Don't draw sigils if an active sigil is present
	if "active" in cDat or sCount == 0:
		return
	
	for sIdx in range(sCount):
		var cNode = get_node(SIGIL_SLOTS[sIdx])
		cNode.texture = load("res://gfx/sigils/%s.png" % cDat.sigils[sIdx])
		cNode.show()


# This could potentially be called multiple times on the same card,
# e.g. when evolving. Therefore costs need to be manually hidden
# when not in use
func draw_costs(cDat: Dictionary) -> void:
	
	var costRoot = get_node("Costs")
	
	for cost in [
		"blood",
		"bone",
		"energy"
	]:
		var costNode = costRoot.get_node(cost)
#		var costs = cDat.get("costs", {})
		
		if not cDat.get(cost + "_cost"):
			costNode.hide()
		else:
			var costValue = cDat.get(cost + "_cost")
			
			costNode.show()
			
			for node in costNode.get_children():
				node.hide()
			
			if costValue < 3 and costValue >= 0:
				costNode.get_node(str(costValue)).show()
				
			else:
				costNode.get_node("TXIcon").show()
				var txtParent = costNode.get_node("Text")
				txtParent.show()
				var txtNodes = txtParent.get_children()
				for txt in txtNodes:
					txt.text = "x" + str(costValue)
				costNode.get_node("Text").rect_min_size.x = 39 + 18 * (len(str(costValue)) - 1)
#				costNode.get_node("Text").rect_min_size.x = 39 + (18 * floor(log(costValue) / log(10)))
	
	var moxNames = [
			"Orange",
			"Blue",
			"Green"
		]
	
	var mox_node = costRoot.get_node("mox")
	
	if cDat.get("mox_cost"):
		mox_node.show()
		
		for moxName in moxNames:
			mox_node.get_child(moxNames.find(moxName)).visible = moxName in cDat.get("mox_cost")
	else:
		mox_node.hide()
#		for moxName in moxNames:
#			costRoot.get_node("mox").get_child(moxNames.find(moxName)).hide()
		
			
# Conduit sigil
func draw_conduit(cDat: Dictionary) -> void:
	$Sigils/ConduitIndicator.visible = "conduit" in cDat

func draw_active(cDat: Dictionary) -> void:
	if "active" in cDat and cDat.get("sigils"):
		$Active.show()
		$Active/ActiveIcon.texture = load("res://gfx/sigils/" + cDat.sigils[0] + ".png")
	else:
		$Active.hide()

# Hover, click handlers
func _on_CardBtn_button_down() -> void:
	modulate = HVR_COLOURS[2]

func _on_CardBtn_button_up() -> void:
	if modulate == HVR_COLOURS[2]:
		modulate = HVR_COLOURS[1]
	
	# Trigger a press action
	if has_method("_on_Button_pressed"):
		self.call("_on_Button_pressed")
	else:
		get_parent()._on_Button_pressed()
		

func _on_CardBtn_mouse_entered() -> void:
	if modulate == HVR_COLOURS[0]:
		modulate = HVR_COLOURS[1]
#		print("Mouse entered")

	if has_method("_on_Card_mouse_entered"):
		call("_on_Card_mouse_entered")


func _on_CardBtn_mouse_exited() -> void:
	modulate = HVR_COLOURS[0]


func _on_Active2_mouse_entered() -> void:
	if modulate == HVR_COLOURS[0]:
		modulate = HVR_COLOURS[1]
		print("Mouse entered active")

func _on_Active2_mouse_exited() -> void:
	modulate = HVR_COLOURS[0]


func _on_Active_button_down() -> void:
	$Active/ActiveIcon.rect_position = Vector2(6, 16)
	get_parent()._on_ActiveSigil_pressed()
	


func _on_Active_button_up() -> void:
	$Active/ActiveIcon.rect_position = Vector2(6, 6)

