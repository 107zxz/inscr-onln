extends Node

var pid = -1

signal recieved_output(line)
signal process_ended()

func start_tunnel():
	print("Starting tunnel")
	
	# Clear / create log file
	var lf = File.new()
	lf.open(CardInfo.tunnellog_path, File.WRITE)
	lf.close()
	
	# Add a delay here for safety, maybe it will fix the bugs?
	yield(get_tree().create_timer(0.25), "timeout")
	
	print(CardInfo.tunnellog_path.replace("/", "\\"))
	
	# These commands for windows systems
	if OS.get_name() == "Windows":
		print("Executing windows commands")
#		OS.execute ("cmd.exe", ["/c", "TYPE NUL > '" + CardInfo.tunnellog_path + "'"], true)
		pid = OS.execute ("cmd.exe", ["/c", "ssh srv.us -R 1:localhost:10567 > \"" + CardInfo.tunnellog_path.replace("/", "\\") + "\""], false)
	# These commands for OSX / Linux systems
	else:
		print("Executing Linux / OSX commands")
#		OS.execute ("bash", ["-c", "echo \"\" > '" + CardInfo.tunnellog_path + "'"], true)
		pid = OS.execute ("bash", ["-c", "ssh srv.us -R 1:localhost:10567 > '" + CardInfo.tunnellog_path + "'"], false)
	
	var fiel = File.new()
	
	var current_size = 0
	
	print("Opening '", CardInfo.tunnellog_path, "' with err code: ", fiel.open(CardInfo.tunnellog_path, File.READ))
	while OS.is_process_running(pid):
		yield(get_tree().create_timer(1), "timeout")
		
		if fiel.get_len() > current_size:
			print(current_size, " : ", fiel.get_len())
			print("got tunnel output: ", fiel.get_as_text().right(current_size))
			
			emit_signal("recieved_output", fiel.get_as_text().right(current_size))
			
			current_size = fiel.get_len()
	
	fiel.close()
	
	print("Process died")
	emit_signal("process_ended")
		
func kill_tunnel():
	if pid > 0 and OS.is_process_running(pid):
		print("Killing tunnel with pid ", pid)
		if OS.get_name() == "Windows":
			
			# As windows PID is arbitrary, need to do this
			# This WILL interfere with other SSH sessions, write this somewhere
			# or fix by parsing tasklist
			OS.execute("taskkill", ["/IM", "ssh.exe", "/F"])
			
		else:
			# Because of how pipes work, we need to do this (on linux at least)
			print("Error code: ", OS.kill(pid+1))

func _exit_tree():
	kill_tunnel()
