extends CanvasLayer
@onready var label: Label = $Label

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	$Label.text = str(Engine.get_frames_per_second()) + " fps"
	pass
