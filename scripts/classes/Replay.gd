class_name Replay

var fileName = "replay.rpl"

var replay = {}

var currentTurn = null

func start(yourName: String, enemyName: String):
	
	var dt = Time.get_datetime_dict_from_system()
	
	var minString = str(dt.minute)
	
	if len(minString) == 1:
		minString = "0" + minString
	
	var dateString = "%s:%s %s-%s-%s" % [dt.hour, minString, dt.day, dt.month, dt.year]
	
	fileName = "%s vs %s %s.irp" % [yourName.left(9), enemyName.left(9), dateString]
	
	print("Created replay with name \"", fileName, "\"")
	
	replay = {
		"players": [yourName, enemyName],
		"turns": [
			
		]
	}
	
	currentTurn = {
		"player": yourName,
		"actions": [
			
		]
	}
	
	return self

func record_action(event: Dictionary):
	
	currentTurn.actions.append(event)
	pass

func end_turn():
	
	replay.turns.append(currentTurn.duplicate())
	
	currentTurn = {
		"player": replay.players[1],
		"actions": [
			
		] 
	}

func start_turn():
	
	replay.turns.append(currentTurn.duplicate())
	
	currentTurn = {
		"player": replay.players[1],
		"actions": [
			
		]
	}
	
func save():
	end_turn()

	if not GameOptions.save_replays:
		return
	
	var d = Directory.new()
	
	if not d.dir_exists(CardInfo.replay_path):
		d.make_dir(CardInfo.replay_path)
	
	var f = File.new()

	print("Attempting to save replay to ", CardInfo.replay_path + fileName)

	print(f.open(CardInfo.replay_path + fileName, File.WRITE))
	f.store_line(to_json(replay))
	f.close()
	
