extends Control

var download_length: int = 0
var progress: float = 0.5
var curr_rot: float = -60

# TODO: Rework this and fully replace the game's pck file. Only way to do this w/ singletons

func _ready():
	$UpdateBox/VBoxContainer/Label.text = "Update from " + CardInfo.VERSION \
	+ " to " + CardInfo.latest_version + "?"


func _process(delta):
	progress = $HTTPRequest.get_downloaded_bytes() / $HTTPRequest.get_body_size()
	
	$Label.text = "%.2f%%" % (progress * 100.0)
	
	$"The boy".rect_rotation = 360.0 * progress - 60.0


func _on_Yes_pressed():
	$UpdateBox.hide()
	$"The boy".show()
	$Label.show()
	
	# KILL THIS
	CardInfo.latest_version = "v0.3.0"
	
	# Request latest version from github
	$HTTPRequest.download_file = OS.get_executable_path().get_basename() + ".pck"
	var res = $HTTPRequest.request("https://github.com/107zxz/inscr-onln/releases/download/%s/patch.pck" % CardInfo.latest_version)
	if res != OK:
		print("Failed downloading\n%s!" % "https://github.com/107zxz/inscr-onln/releases/download/%s/patch.pck" % CardInfo.latest_version)
		print(res)
		print($HTTPRequest.get_downloaded_bytes())
		$UpdateBox.show()
		$"The boy".hide()
		$Label.hide()

func _on_No_pressed():
	get_tree().change_scene("res://NewMain.tscn")


func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	if body.size() > 300 and response_code == OK:
#		var f = File.new()
#		f.open(OS.get_executable_path().get_basename() + ".pck")
#		f.write(body)
#		f.close()
		
		# Reboot
		OS.execute(OS.get_executable_path(), [], false)
		get_tree().quit()
		
		# Hot-patch
#		ProjectSettings.load_resource_pack("user://patch.pck")
		
#		get_tree().change_scene("res://packed/RulesetPickerProto.tscn")
