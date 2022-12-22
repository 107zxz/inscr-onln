extends Panel

var line_prefab = preload("res://packed/RulesetLine.tscn")

var visible_rulesets = []

# UI
func _on_RSFF_pressed():
	$FromFile.popup_centered()

func ARGIT():
	randomize()
	
#	if randi() % 10 == 0 and GameOptions.options.misplays < 2 and not GameOptions.mega_misplay: # TODO: Change this when adding more
	if GameOptions.options.misplays < 3 and not GameOptions.mega_misplay:
		
		var p = randi() % 10
		
		if p == 03:
			get_tree().change_scene("res://ARG/Scenes/Void.tscn")

func _ready():
	
	ARGIT()
	
	
	$VersionLabel.text = CardInfo.VERSION
	
	var d = Directory.new()
	d.make_dir(CardInfo.rulesets_path)
	
	$Status.show()
	fetch_featured_rulesets()
	fetch_saved_rulesets()

func errorBox(message: String):
	$Error/PanelContainer/VBoxContainer/Label.text = message
	$Error.show()

func _on_FromFile_file_selected(path):
	add_ruleset_from_file(path)

func _on_URLDownloadBtn_pressed():
	add_ruleset_from_url($FromURL/PanelContainer/VBoxContainer/LineEdit.text)
	$FromURL.hide()
	
func _on_JSONLoadBtn_pressed():
	add_ruleset_from_json($FromJSON/PanelContainer/VBoxContainer/TextEdit.text)
	$FromJSON.hide()

# Ruleset Management
func use_ruleset(dat: Dictionary):
	CardInfo.rules_path = CardInfo.rulesets_path + dat.ruleset + ".json"
	CardInfo.read_game_info()
	
	GameOptions.mega_misplay = true
	
	get_tree().change_scene("res://NewMain.tscn")

func delete_ruleset(lineObject: Control, rsName: String):
	
	# Delete ruleset file
	var d = Directory.new()
	d.remove(CardInfo.rulesets_path + rsName + ".json")
	
	if rsName in visible_rulesets:
		visible_rulesets.erase(rsName)
		
	lineObject.queue_free()

func default_ruleset(toggled: bool, lineObject: Control, rsName: String):
	
	print("I can I can't")
	
	if toggled:
		pass
	else:
		GameOptions.options.default_ruleset = ""
		for rs in $SavedRulesets.get_children():
			if rs != lineObject:
				rs.get_node("HBoxContainer/Default").pressed = false

func fetch_saved_rulesets():
	var d = Directory.new()
	
	d.open(CardInfo.rulesets_path)
	
	d.list_dir_begin()
	
	while true:
		var file = d.get_next()
		if file == "":
			break
		
		if not ".json" in file:
			continue
		
		print("Adding from file ", file)
		add_ruleset_from_file(CardInfo.rulesets_path + file)
	
	d.list_dir_end()

func fetch_featured_rulesets():
	$FeaturedFetcher.request("https://raw.githubusercontent.com/107zxz/inscr-onln-ruleset/main/featured.json")

func _on_FeaturedFetcher_request_completed(_result, response_code, _headers, body):
	
	if response_code != 200:
		errorBox("Failed fetching featured\nResponse code " + str(response_code))
		return
	
	var featured = parse_json(body.get_string_from_utf8())
	
	$Status.hide()
	
	# Jake
	$Jake.show()
	$Jakebubble.show()
	$Jakebubble/Jakemsg.text = featured.jake
	
	for rs_dat in featured.rulesets:
		add_featured_ruleset_from_dat(rs_dat)

# Add rulesets
func add_featured_ruleset_from_dat(dat: Dictionary):
	
	var nl = line_prefab.instance()
	$FeaturedRulesets/VBoxContainer/ScrollContainer/FeatRsCont.add_child(nl)
	nl.get_node("HBoxContainer/RSName").text = dat.name + ("\n\n" + dat.description if "description" in dat else "")
	
	if "portrait" in dat:
		nl.get_node("HBoxContainer/RSPort").texture = load("res://gfx/" + dat.portrait + ".png")
	
	# Thing
	var rsdl = nl.get_node("HBoxContainer/RSDL")
	rsdl.show()
	rsdl.connect("pressed", self, "add_ruleset_from_url", [dat.url])
	
func add_ruleset_from_url(url: String):
	print("Adding ruleset from url: ", url)
	$Status.show()
	$Status/PanelContainer/HBoxContainer/Label.text = "Downloading Ruleset..."
	$RSDownloader.request(url)

func _on_RSDownloader_request_completed(_result, response_code, _headers, body):
	if response_code != 200:
		errorBox("Failed downloading ruleset\nResponse code " + str(response_code))
		return
	
	$Status.hide()
	
	var jString = body.get_string_from_utf8()
	
	var jDat = parse_json(jString)
	
	download_card_portraits(jDat)
	download_sigil_icons(jDat)
	
	add_ruleset_from_json(jString)

func add_ruleset_from_file(filename: String):
	var file = File.new()
	file.open(filename, File.READ)
	var cnt = file.get_as_text()
	file.close()
	add_ruleset_from_json(cnt)

func add_ruleset_from_json(json: String):
	
	var ruleset = parse_json(json)
	
	if not ruleset.ruleset in visible_rulesets:
		add_saved_ruleset_entry_dat(ruleset)
		visible_rulesets.append(ruleset.ruleset)
	
	var fd = File.new()
	fd.open(CardInfo.rulesets_path + ruleset.ruleset + ".json", File.WRITE)
	fd.store_string(json)
	fd.close()
	
#	fetch_saved_rulesets()

func add_saved_ruleset_entry_dat(dat):
	
	var nl = line_prefab.instance()
	$SavedRulesets/VBoxContainer/ScrollContainer/SavedRsCont.add_child(nl)
	nl.get_node("HBoxContainer/RSName").text = dat.ruleset + ("\n\n" + dat.description if "description" in dat else "")
	
	if "portrait" in dat:
		nl.get_node("HBoxContainer/RSPort").texture = load("res://gfx/" + dat.portrait + ".png")
	
	# Thing
	var ub = nl.get_node("HBoxContainer/RSUse")
	var db = nl.get_node("HBoxContainer/RSDelete")
	var defb = nl.get_node("HBoxContainer/Default")
	
	ub.show()
	ub.connect("pressed", self, "use_ruleset", [dat])
	db.show()
	db.connect("pressed", self, "delete_ruleset", [nl, dat.ruleset])
	defb.show()
	db.connect("toggled", self, "default_ruleset", [nl, dat.ruleset])


func download_card_portraits(dat):
	var d = Directory.new()

	if not d.dir_exists(CardInfo.custom_portrait_path):
		d.make_dir(CardInfo.custom_portrait_path)
	
	if not d.dir_exists(CardInfo.portrait_override_path):
		d.make_dir(CardInfo.portrait_override_path)
	
	for card in dat.cards:
		if "pixport_url" in card:
			
			var fp = CardInfo.custom_portrait_path + dat.ruleset + "_" + card.name + ".png"
			
			if d.file_exists(fp):
				continue
			
			$ImageRequest.download_file = fp
			$ImageRequest.request(card.pixport_url)
			
			yield($ImageRequest, "request_completed")
	
func download_sigil_icons(dat):
	var d = Directory.new()

	if not d.dir_exists(CardInfo.custom_icon_path):
		d.make_dir(CardInfo.custom_icon_path)
	
	if not d.dir_exists(CardInfo.icon_override_path):
		d.make_dir(CardInfo.icon_override_path)
	
	if "sigil_urls" in dat:
		for sigil in dat.sigil_urls:
			var fp = CardInfo.custom_icon_path + dat.ruleset + "_" + sigil + ".png"
			
			if d.file_exists(fp):
				continue
			
			$ImageRequest.download_file = fp
			$ImageRequest.request(dat.sigil_urls[sigil])
			
			yield($ImageRequest, "request_completed")
