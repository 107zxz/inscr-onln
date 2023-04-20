extends Node

signal failed(why)
signal success(code)


const LOCAL_ADDR = "127.0.0.1"
const LOCAL_PORT = 10567


class Stream extends StreamPeerTCP:
	var _address: String
	var _port: int
	var _status: int
	var _old_status: int
	
	func _init(address, port) -> void:
		_address = address
		_port = port
		_status = StreamPeerTCP.STATUS_NONE
	
	func connect_to_stored_host() -> int:
		return connect_to_host(_address, _port)
	
	func get_status() -> int:
		return _status
	
	func poll() -> void:
		_old_status = _status
		_status = get_status()
	
	func status_fresh() -> bool:
		return _old_status != _status
		
	func get_address() -> String:
		return _address
		

var local_stream: Stream = null
var remote_stream: Stream = null

# Sockets
var http_client = HTTPRequest.new()


func _ready():
	add_child(http_client)
	http_client.connect("request_completed", self, "_rq_completed")


func establish_tunnel(code: String = ""):
	
	if not code:
		http_client.request("https://localtunnel.me/?new")
	else:
		http_client.request("https://localtunnel.me/%s" % code)


func establish_tunnel_between(addr_1: String, port_1: int, addr_2: String, port_2: int):
	
	local_stream = Stream.new(addr_1, port_1)
	remote_stream = Stream.new(addr_2, port_2)
	
	print("-----\nForming 2-way proxy between:\n%s:%d\nand\n%s:%d\n-----" %
		[
			addr_1,
			port_1,
			addr_2,
			port_2
		]
	)
	
	var err0 = local_stream.connect_to_stored_host()
	
	if err0 != 0:
		emit_signal("failed", "Failed to connect socket to local server. Error code %d", err0)
		return
		
	var err1 = remote_stream.connect_to_stored_host()
	
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
	
	if local_stream == null or remote_stream == null:
		return
	
	for stream in [local_stream, remote_stream]:
		
		stream.poll()
		
		if stream.status_fresh():
			match stream.get_status():
				StreamPeerTCP.STATUS_NONE:
					print("Stream %s disconnected from host" % stream.get_address())
					
					# Force a reconnection
#					streams[id].connect_to_host([LOCAL_ADDR, REMOTE_ADDR][id], [LOCAL_PORT, REMOTE_PORT][id])
					
					stream.connect_to_stored_host()
					
#					emit_signal("failed", "Stream %d disconnected from host." % id)
#					kill_tunnel()
				StreamPeerTCP.STATUS_CONNECTING:
					print("Stream %s connecting to host" % stream.get_address())
#					print("Stream %d connecting to host." % id)
					pass
				StreamPeerTCP.STATUS_CONNECTED:
					print("Stream %s connected to host" % stream.get_address())
#					print("Stream %d connected to host." % id)
					if stream == remote_stream:
						emit_signal("success")
				StreamPeerTCP.STATUS_ERROR:
					print("Stream %s SOCKET ERROR" % stream.get_address())
#					print("Stream %d error with socket stream." % id)
#					emit_signal("failed", "Stream %d error with socket stream." % id)
					kill_tunnel()

		if stream.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			var available_bytes: int = stream.get_available_bytes()
			if available_bytes > 0:
				var data: Array = stream.get_partial_data(available_bytes)
				
				print("DATA: %d", available_bytes)
				
				# Check for read error.
				if data[0] != OK:
					print("Error getting data from stream %s: ", stream.get_address())
				else:
					(remote_stream if stream == local_stream else local_stream).put_data(data[1])


func kill_tunnel():
	
	print("Closing streams...")
	
	for stream in [local_stream, remote_stream]:
		if stream.is_connected_to_host():
			stream.disconnect_from_host()
