extends Control

var raised = false

func _ready():
	$TextureButton.connect("pressed", self, "toggle")
	$TextureButton.connect("pressed", get_parent().get_parent(), "_ruleset_card_clicked", [self])

func raise():
	if not raised and not $AnimationPlayer.is_playing():
		$AnimationPlayer.play("raise")
		raised = true
	
func lower():
	if raised and not $AnimationPlayer.is_playing():
		$AnimationPlayer.play("lower")
		raised = false
	

func toggle():
	if raised:
		lower()
	else:
		raise()
