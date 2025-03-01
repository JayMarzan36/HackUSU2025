extends TouchScreenButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if is_pressed():
		print("Pressed")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
