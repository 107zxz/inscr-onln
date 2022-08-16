extends Control

const rulesetURLs = [
	"https://raw.githubusercontent.com/107zxz/inscr-onln-ruleset/main/competitive.json",
	null,
	null,
	null,
	"https://raw.githubusercontent.com/107zxz/inscr-onln-ruleset/main/sandbox.json"
]

func _ready():
	for option in OS.get_cmdline_args():
		if option == "noupdate":
#			get_tree().change_scene("res://NewMain.tscn")
			return
	
	get_node("VersionLabel").text = CardInfo.VERSION

func _on_Continue_pressed():
	
	$SelectionBox.visible = false
	
	$LoadingBox.visible = true
	$LoadingBox/AnimationPlayer.play("progress")
	
	var rulesetUrl = $SelectionBox/Rows/Url.text
	
	if $SelectionBox/Rows/OptionButton.selected < 5:
		rulesetUrl = rulesetURLs[$SelectionBox/Rows/OptionButton.selected]
	
	if $SelectionBox/Rows/OptionButton.selected == 6:
		CardInfo.read_game_info()
		
		print("Using cached ruleset")
		
		# Special, download portraits (maybe remove this later)
		download_card_portraits()
		
#		get_tree().change_scene("res://NewMain.tscn")
		return
	
	print("Downloading ruleset from url: " + rulesetUrl)
	
	# Should I update?
	if $RulesetRequest.request(rulesetUrl) != 0:
		$SelectionBox.visible = true
		$LoadingBox.visible = false
		
		$SelectionBox/Rows/ErrLabel.visible = true
		$SelectionBox/Rows/ErrLabel.text = "Invalid URL"



func _on_RulesetRequest_request_completed(_result, response_code, _headers, body):
	if response_code == 200:
		var parse = JSON.parse(body.get_string_from_utf8())
		print(parse.result.ruleset)
		if parse.error != 0:
			$SelectionBox.visible = true
			$LoadingBox.visible = false
			
			$SelectionBox/Rows/ErrLabel.visible = true
			$SelectionBox/Rows/ErrLabel.text = "Target file contains invalid JSON"
			return
		
		if not "cards" in parse.result:
			$SelectionBox.visible = true
			$LoadingBox.visible = false
			
			$SelectionBox/Rows/ErrLabel.visible = true
			$SelectionBox/Rows/ErrLabel.text = "Target URL is not a valid ruleset"
			return
		
		var f = File.new()
		f.open(CardInfo.rules_path, File.WRITE)
		f.store_line(body.get_string_from_utf8())
		f.close()
		
		CardInfo.read_game_info()
		
		print("Ruleset updated successfully")
		
		download_card_portraits()
		
		
	else:
		print("ERROR UPDATING RULESET")
		$SelectionBox.visible = true
		$LoadingBox.visible = false
		
		$SelectionBox/Rows/ErrLabel.visible = true
		$SelectionBox/Rows/ErrLabel.text = "Target file gave error " + str(response_code)


func _on_OptionButton_item_selected(index):
	if index == 5:
		$SelectionBox/Rows/Url.visible = true
	else:
		$SelectionBox/Rows/Url.visible = false

func download_card_portraits():
	var d = Directory.new()

	# TODO: Make directory if possible
	if not d.dir_exists(CardInfo.custom_portrait_path):
		d.make_dir(CardInfo.custom_portrait_path)
	
	if not d.dir_exists(CardInfo.portrait_override_path):
		d.make_dir(CardInfo.portrait_override_path)
	
	for card in CardInfo.all_cards:
		if "pixport_url" in card:
			
			var fp = CardInfo.custom_portrait_path + card.name + ".png"
			
			if d.file_exists(fp):
				print("File %s already exists! Skipping download" % fp)
				continue
			
			$ImageRequest.download_file = fp
			$ImageRequest.request(card.pixport_url)
			print("Requesting image %s..." % card.pixport_url)
			
			yield($ImageRequest, "request_completed")

	# Now switch to main scene
	get_tree().change_scene("res://NewMain.tscn")
	

func _on_ImageRequest_request_completed(_result, response_code, _headers, _body):
	if response_code != 200:
		print("Error downloading! Skipping...")
	
