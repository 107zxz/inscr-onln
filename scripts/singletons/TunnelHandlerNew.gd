extends Node

signal failed(why)
signal success(code)

# Sockets
var streams = [StreamPeerTCP.new(), StreamPeerTCP.new()]
var status = [0, 0]

var http_client = HTTPRequest.new()

var LOCAL_ADDR = "127.0.0.1"
var LOCAL_PORT = 10567
var REMOTE_ADDR = ""
var REMOTE_PORT = 0

func _ready():
	add_child(http_client)
	http_client.connect("request_completed", self, "_rq_completed")


func establish_tunnel(code: String = ""):
	
	if not code:
		http_client.request("https://localtunnel.me/?new")
	else:
		http_client.request("https://localtunnel.me/%s" % code)


func establish_tunnel_between(addr_1: String, port_1: int, addr_2: String, port_2: int):
	
	LOCAL_ADDR = addr_1
	LOCAL_PORT = port_1
	REMOTE_ADDR = addr_2
	REMOTE_PORT = port_2
	
	print("-----\nForming 2-way proxy between:\n%s:%d\nand\n%s:%d\n-----" %
		[
			addr_1,
			port_1,
			addr_2,
			port_2
		]
	)
	
	var err0 = streams[0].connect_to_host(addr_1, port_1)
	
	if err0 != 0:
		emit_signal("failed", "Failed to connect socket to local server. Error code %d", err0)
		return
		
	var err1 = streams[1].connect_to_host(addr_2, port_2)
	
	if err1 != 0:
		emit_signal("failed", "Failed to connect socket to remote server. Error code %d", err0)
		return

func _rq_completed(_result, response_code, _headers, body):
	
	if response_code != 200:
		emit_signal("failed", "Contacting localtunnel.me failed with response code: %d" % response_code)
		return
	
	var data = parse_json(body.get_string_from_utf8())
	
	establish_tunnel_between(LOCAL_ADDR, LOCAL_PORT, data.url.substr(8), data.port)


func _process(_delta: float) -> void:
	
	for id in [0, 1]:
		
		var new_status = streams[id].get_status()
	
		if status[id] != new_status:
			status[id] = new_status
			match new_status:
				StreamPeerTCP.STATUS_NONE:
#					print("Stream %d disconnected from host." % id)
					
					# Force a reconnection
					streams[id].connect_to_host([LOCAL_ADDR, REMOTE_ADDR][id], [LOCAL_PORT, REMOTE_PORT][id])
					
#					emit_signal("failed", "Stream %d disconnected from host." % id)
#					kill_tunnel()
				StreamPeerTCP.STATUS_CONNECTING:
#					print("Stream %d connecting to host." % id)
					pass
				StreamPeerTCP.STATUS_CONNECTED:
#					print("Stream %d connected to host." % id)
					if id == 1:
						emit_signal("success")
				StreamPeerTCP.STATUS_ERROR:
#					print("Stream %d error with socket stream." % id)
#					emit_signal("failed", "Stream %d error with socket stream." % id)
					kill_tunnel()

		if new_status == StreamPeerTCP.STATUS_CONNECTED:
			var available_bytes: int = streams[id].get_available_bytes()
			if available_bytes > 0:
				var data: Array = streams[id].get_partial_data(available_bytes)
				# Check for read error.
				if data[0] != OK:
					print("Error getting data from stream %d: ", [id, data[0]])
				else:
					streams[1-id].put_data(data[1])


func kill_tunnel():
	
	print("Closing streams...")
	
	for stream in streams:
		if stream.is_connected_to_host():
			stream.disconnect_from_host()
