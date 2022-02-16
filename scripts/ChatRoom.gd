extends Control

onready var main_cont = get_node("/root/Main")

remote func recieve_message(msg):
	var pName = "ERR"
	
	if get_tree().is_network_server():
		pName = main_cont.challengers[main_cont.opponent]
	else:
		pName = main_cont.challengers[1]
	
	$VBoxContainer/Panel/ChatLog.text += pName + ": " + msg + "\n"

func send_message():
	var targetid = 1
	if get_tree().is_network_server():
		targetid = main_cont.opponent
	
	# Display your message client side
	var pName = main_cont.get_node("Lobby/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer2/uname").text
	
	$VBoxContainer/Panel/ChatLog.text += pName + ": " + $VBoxContainer/HBoxContainer/textEdit.text + "\n"
	
	# Send message to other player
	rpc_id(targetid, "recieve_message", $VBoxContainer/HBoxContainer/textEdit.text)
	$VBoxContainer/HBoxContainer/textEdit.clear()


func _on_sendButton_pressed():
	send_message()


func _on_textEdit_text_entered(_new_text):
	send_message()

func kick_other():
	main_cont.chat_kick(main_cont.opponent)


func _on_exitButton_pressed():
	if get_tree().is_network_server():
		kick_other()
	else:
		get_tree().network_peer = null
	
	visible = false

func open():
	var pName = "ERR"
	if get_tree().is_network_server():
		pName = main_cont.challengers[main_cont.opponent]
	else:
		pName = main_cont.challengers[1]
	$VBoxContainer/Panel/ChatLog.text = "Chatting with " + pName + "\n"
	
