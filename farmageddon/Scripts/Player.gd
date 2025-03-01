extends CharacterBody2D

var tools = {"empty" : [0.0],"hoe" : [0.0], "waterCan" : [0.0], "axe" : [0.0]}
@onready var _animated_sprite = $AnimatedSprite2D
var toolPath = "res://assets/Sprout Lands - Sprites - Basic pack/Characters/Tools.png"
@onready var currentTool = tools.get("empty")
const SPEED = 300.0

func get_input():
	var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	
	velocity = input_direction * SPEED
	
func _physics_process(delta: float) -> void:
	get_input()
	move_and_slide()

func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_left"):
		_animated_sprite.play("Walk Left")
	
	elif Input.is_action_pressed("ui_right"):
		_animated_sprite.play("Walk Right")
		
	elif Input.is_action_pressed("ui_up"):
		_animated_sprite.play("Walk Up")
		
	elif Input.is_action_pressed("ui_down"):
		_animated_sprite.play("Walk Down")

	else:
		_animated_sprite.stop()
