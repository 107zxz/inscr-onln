extends SigilEffect

# This is called whenever something happens that might trigger a sigil, with 'event' representing what happened
func handle_event(event: String, params: Array):

	# attached_card_summoned represents the card bearing the sigil being summoned
	if event == "card_summoned" and params[0] == card:
		var songUrl = card.card_data.song
		
		var rq = HTTPRequest.new()
		card.add_child(rq)
		
		rq.connect("request_completed", self, "download_callback")
		rq.download_file = CardInfo.data_path + "/juke.mp3"
		rq.request(songUrl)
		
		fightManager.get_node("MusInfo").visible = true

	if event == "card_perished" and params[0] == card:
		fightManager.get_node("MusPlayer").stop()

		

func download_callback(_result, response_code, _headers, body):
	
	var player = fightManager.get_node("MusPlayer")
	card.add_child(player)
	
	var f = File.new()
	f.open(CardInfo.data_path + "/juke.mp3", File.READ)
	var strm = AudioStreamMP3.new()
	strm.data = f.get_buffer(f.get_len())
	f.close()
	
	player.stream = strm
	player.play()
	
	fightManager.get_node("MusInfo").visible = false
