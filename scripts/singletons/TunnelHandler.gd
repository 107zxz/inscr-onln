extends Node

var library = load("res://native/tunnellib.tres")
var scpt = null
var resume = null
var tunnelFunc = null

signal received_output(code)

func _ready():
	scpt = NativeScript.new()
	scpt.set_library(library)
	scpt.set_class_name("AsyncMethods")
	resume = Reference.new()
	resume.set_script(scpt)
	
#	start_tunnel()

func start_tunnel(lname):
	tunnelFunc = resume.open_tunnel(self, lname)
	if !tunnelFunc:
		printerr("Failed to create function state!!")
		return
	print("Started tunnel")

func kill_tunnel():
	if tunnelFunc:
		print("Killing tunnel")
		tunnelFunc.resume()

func tunnel_callback(url):
	print("URL From tunnel: ", url)
	
	var rcode = url.split("https://")[1].split(".loca.lt")[0]
	
	emit_signal("received_output", rcode)
	
	print("Parsed room code: ", rcode)

func _exit_tree():
	if tunnelFunc:
		print("Killing tunnel")
		tunnelFunc.resume()
	
