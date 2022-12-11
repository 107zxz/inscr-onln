extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	if "noupdate" in OS.get_cmdline_args():
		return
		
	$HTTPRequest.request("https://raw.githubusercontent.com/107zxz/inscr-onln-ruleset/main/motd.json")
	

func _on_HTTPRequest_request_completed(_result, response_code, _headers, body):
	if response_code == 200:
		var parse = JSON.parse(body.get_string_from_utf8())
		
		if parse.error:
			print("Error parsing update JSON, %s!" % parse.error)
			return
		
		var res = parse.result
		
		if res.latest_version != CardInfo.VERSION:
			$PatchStoats.visible = true
			$PatchStoats/Notes.text = res.motd_stoat
		
		if res.motd_stoat_force != "":
			$PatchStoats.visible = true
			$PatchStoats/Notes.text = res.motd_stoat_force
		
#		if "IMF Competitive" in CardInfo.ruleset and res.latest_ruleset != CardInfo.ruleset:
#			$Grimorger.visible = true
#			$Grimorger/Notes.text = res.motd_grimorger_update
		
		if res.motd_grimorger != "":
			$Grimorger.visible = true
			$Grimorger/Notes.text = res.motd_grimorger

func _on_Button_pressed():
	OS.shell_open("https://107zxz.itch.io/inscryption-multiplayer-godot")
