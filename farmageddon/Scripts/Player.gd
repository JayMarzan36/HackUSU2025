extends CharacterBody2D

var tools = {"empty" : [0.0],"hoe" : [0.0], "waterCan" : [0.0], "axe" : [0.0]}
@onready var animated_sprite = $AnimatedSprite2D
var toolPath = "res://assets/Sprout Lands - Sprites - Basic pack/Characters/Tools.png"
@onready var currentTool = tools.get("empty")
const SPEED = 300.0
var parent_node = null

func _ready():
	# Find the parent node (PlayerWithGUI)
	parent_node = get_parent()
	if parent_node:
		print("Found parent node: " + parent_node.name)
	else:
		print("No parent node found!")
	
	# Add a camera as a child of the player
	var camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.enabled = true
	
	# Configure camera to work with UI elements
	camera.ignore_rotation = true
	
	# Make sure it doesn't block input to UI elements
	camera.set_process_input(false)
	
	add_child(camera)
	print("Camera added to player")

func get_input():
	# Check for joystick input first (from parent's joystick if available)
	var joystick_direction = Vector2.ZERO
	if parent_node and parent_node.has_method("get_joystick_direction"):
		joystick_direction = parent_node.get_joystick_direction()
	
	# If no joystick input, fall back to keyboard
	var input_direction = joystick_direction if joystick_direction != Vector2.ZERO else Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Instead of moving this node, set velocity for the parent
	if parent_node:
		parent_node.position += input_direction * SPEED * get_process_delta_time()
	else:
		# Fallback to moving this node if parent isn't found
		velocity = input_direction * SPEED

func _physics_process(delta: float) -> void:
	get_input()
	
	# Only call move_and_slide if we're moving the CharacterBody2D itself
	if not parent_node:
		move_and_slide()

func _process(delta: float) -> void:
	# Update animations based on input
	if Input.is_action_pressed("ui_left"):
		animated_sprite.play("Walk Left")
	elif Input.is_action_pressed("ui_right"):
		animated_sprite.play("Walk Right")
	elif Input.is_action_pressed("ui_up"):
		animated_sprite.play("Walk Up")
	elif Input.is_action_pressed("ui_down"):
		animated_sprite.play("Walk Down")
	else:
		animated_sprite.stop()
