extends CanvasLayer

## Text affiché sur l'écran affiché sur l'écran. [br]
## Le permier modification de la variable doit l'écrasé, les suivante doivent être ajouté.
@export var debugText : String = "- Debug zone -\r"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	$Label.text = str(Engine.get_frames_per_second()) + " fps \r Press R to restart level \r " + "- Debug zone -\r" + debugText
	
	if Input.is_action_just_pressed("restart_level"):
		get_tree().reload_current_scene()
	pass
