extends Node

var pid = -1

func start_tunnel():
	print("Starting tunnel")
	
	pid = OS.execute ("bash", ["-c", "echo \"\" > listing.txt; ssh -R 80:localhost:10567 nokey@localhost.run > listing.txt"], false)
	
#	pid = OS.execute("bash", ["-c", "./cont_output.sh > listing.txt"], false)	
	
	var fiel = File.new()
	
	var current_size = 0
	
	fiel.open("listing.txt", File.READ)
	while OS.is_process_running(pid):
		yield(get_tree().create_timer(1), "timeout")
		
		if fiel.get_len() > current_size:
			print(current_size, " : ", fiel.get_len())
			print("got input: ", fiel.get_as_text().right(current_size))
			current_size = fiel.get_len()
		
func kill_tunnel():
	if pid > 0 and OS.is_process_running(pid):
		print("Killing tunnel")
		
		OS.kill(pid)
