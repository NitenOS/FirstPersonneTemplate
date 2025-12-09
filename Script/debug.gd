extends CanvasLayer

@export var debugText : String = "placeholder debug"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	$Label.text = str(Engine.get_frames_per_second()) + " fps \r Press R to restart level \r " + debugText
	
	if Input.is_action_just_pressed("restart_level"):
		get_tree().reload_current_scene()
	pass
