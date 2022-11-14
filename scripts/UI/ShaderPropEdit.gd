extends HBoxContainer

export (ShaderMaterial) var shaderMat;
export (String) var optionPrefix

onready var children = get_children()

var init = false

func _ready():
	for child in children:
		# Mark nodes to ignore with _
		if child.name[0] != "_":
			
			child.value = GameOptions.options[optionPrefix + child.name]
			
			shaderMat.set_shader_param(child.name, child.value)
			
	init = true
	
	
# Connect all children to this
func _child_updated(_new_val):
	
	if not init:
		return
	
	for child in children:
		# Mark nodes to ignore with _
		if child.name[0] != "_":
			shaderMat.set_shader_param(child.name, child.value)
			
			# Sync to options
			if optionPrefix != "":
				GameOptions.options[optionPrefix + child.name] = child.value
