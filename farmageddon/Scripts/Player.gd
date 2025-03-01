extends CharacterBody2D

var tools = {"empty" : [0.0],"hoe" : [0.0], "waterCan" : [0.0], "axe" : [0.0]}
@onready var animated_sprite = $AnimatedSprite2D
var toolPath = "res://assets/Sprout Lands - Sprites - Basic pack/Characters/Tools.png"
@onready var currentTool = tools.get("empty")

const SPEED = 300.0
var facing_direction = Vector2.DOWN

# Target tile information
var target_tile = Vector2i(0, 0)
var farm = null
var tilemap = null

# GUI reference
var gui_canvas_layer = null
var joystick = null

# Called when the node enters the scene tree for the first time
func _ready():
	# Add a camera as a child of the player
	var camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.enabled = true
	add_child(camera)
	print("Camera added to player")
	
	# Create the tile outline indicator
	create_outline_indicator()
	
	# Find the farm on ready
	find_farm()
	
	# Find and initialize the GUI reference
	find_gui()

# Create a visual indicator for the tile we're going to interact with
func create_outline_indicator():
	# Create a Node2D to hold our outline drawing
	var indicator = Node2D.new()
	indicator.name = "TileOutlineIndicator"
	
	# Add a custom drawing function
	indicator.set_script(GDScript.new())
	indicator.get_script().source_code = """
extends Node2D

var tile_size = Vector2(32, 32)  # Default tile size, adjust as needed
var outline_color = Color(1, 0, 0)  # Red outline
var outline_width = 2.0

func _draw():
	# Draw a rectangle outline centered at origin
	var rect = Rect2(-tile_size/2, tile_size)
	draw_rect(rect, outline_color, false, outline_width)

func update_position(pos):
	position = pos
	queue_redraw()
"""
	indicator.get_script().reload()
	add_child(indicator)
	print("Tile outline indicator created")

# Find the farm and tilemap references
func find_farm():
	var main = get_tree().get_root().get_node_or_null("Main")
	if not main and get_tree().get_root().get_child_count() > 0:
		main = get_tree().get_root().get_child(0)
	
	if main and main.has_method("get_farm"):
		farm = main.get_farm()
		if farm:
			tilemap = farm.get_node("FarmTileMap")
			print("Farm and tilemap references found")
	
	if not farm or not tilemap:
		print("WARNING: Could not find farm or tilemap references")

func get_input():
	var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Update facing direction only when actually moving
	if input_direction != Vector2.ZERO:
		facing_direction = input_direction.normalized()
		# Update indicator position when facing direction changes
		update_indicator_position()
	
	# Calculate desired velocity (simpler approach)
	velocity = input_direction * SPEED
	
	# If we have the farm reference and the player is moving, check collisions
	if farm and farm.has_method("can_move_to") and input_direction != Vector2.ZERO:
		# Calculate the target position
		var target_position = global_position + velocity * get_physics_process_delta_time()
		
		# Only apply velocity if the target position is walkable
		if !farm.can_move_to(target_position):
			# Try sliding along walls by checking x and y movement separately
			var x_position = Vector2(target_position.x, global_position.y)
			var y_position = Vector2(global_position.x, target_position.y)
			
			if farm.can_move_to(x_position):
				velocity.x = input_direction.x * SPEED
				velocity.y = 0
			elif farm.can_move_to(y_position):
				velocity.x = 0
				velocity.y = input_direction.y * SPEED
			else:
				velocity = Vector2.ZERO
	
func _physics_process(delta: float) -> void:
	get_input()
	move_and_slide()

func _process(delta: float) -> void:
	# Handle animation using direct input checks (simpler approach)
	if Input.is_action_pressed("ui_left"):
		animated_sprite.play("Walk Left")
	elif Input.is_action_pressed("ui_right"):
		animated_sprite.play("Walk Right")
	elif Input.is_action_pressed("ui_up"):
		animated_sprite.play("Walk Up")
	elif Input.is_action_pressed("ui_down"):
		animated_sprite.play("Walk Down")
	# If no direct input but velocity exists (from joystick), use the velocity-based animation
	elif velocity.length() > 0:
		if abs(velocity.x) > abs(velocity.y):
			if velocity.x > 0:
				animated_sprite.play("Walk Right")
			else:
				animated_sprite.play("Walk Left")
		else:
			if velocity.y > 0:
				animated_sprite.play("Walk Down")
			else:
				animated_sprite.play("Walk Up")
	else:
		animated_sprite.stop()
	
	# Update indicator position every frame to follow the player
	update_indicator_position()
	
	# Handle interaction with farm
	if Input.is_action_just_pressed("ui_accept"):  # Enter key
		interact_with_farm()
		
	# Update the GUI position
	update_gui_position()

# Update the position of the indicator to show the tile we would interact with
func update_indicator_position():
	if not farm or not tilemap:
		find_farm()
		if not farm or not tilemap:
			return
	
	# Get the player's current tile position
	var player_tile_pos = tilemap.local_to_map(tilemap.to_local(global_position))
	
	# Determine which tile is in front based on facing direction
	var dir_x = 0
	var dir_y = 0
	
	# Round the facing direction to get a clean directional vector
	if abs(facing_direction.x) > abs(facing_direction.y):
		# Horizontal movement is dominant
		dir_x = 1 if facing_direction.x > 0 else -1
		dir_y = 0
	else:
		# Vertical movement is dominant
		dir_x = 0
		dir_y = 1 if facing_direction.y > 0 else -1
	
	# Calculate the tile position in front
	target_tile = Vector2i(player_tile_pos.x + dir_x, player_tile_pos.y + dir_y)
	
	# Convert target tile to world position (center of the tile)
	var target_pos = tilemap.to_global(tilemap.map_to_local(target_tile))
	
	# Update indicator position
	var indicator = get_node_or_null("TileOutlineIndicator")
	if indicator and indicator.has_method("update_position"):
		# Calculate relative position to player
		var relative_pos = target_pos - global_position
		indicator.update_position(relative_pos)
		
		# Update indicator color based on whether the tile is walkable
		if farm and farm.has_method("is_tile_walkable"):
			var is_walkable = farm.is_tile_walkable(target_tile)
			var script = indicator.get_script()
			script.source_code = script.source_code.replace(
				"var outline_color = Color(1, 0, 0)",  # Red outline
				"var outline_color = Color(%s, %s, %s)" % [
					"0" if is_walkable else "1",  # R
					"1" if is_walkable else "0",  # G
					"0"                          # B
				]
			)
			script.reload()

func interact_with_farm():
	if not farm or not tilemap:
		find_farm()
		if not farm or not tilemap:
			print("No farm found to interact with")
			return
			
	print("Interacting with tile:", target_tile)
	
	# Use the direct tile interaction method if available
	if farm.has_method("interact_at_tile"):
		farm.interact_at_tile(target_tile)
	else:
		# Fallback to the world position method
		var world_pos = tilemap.to_global(tilemap.map_to_local(target_tile))
		farm.on_player_interaction(world_pos)
		
# Find the GUI canvas layer and joystick
func find_gui():
	# Try multiple approaches to find the joystick
	
	# Method 1: Look for it in the scene tree, starting from the root
	var root = get_tree().get_root()
	
	# Try to find any CanvasLayer in the scene
	var canvas_layers = []
	for i in range(root.get_child_count()):
		var node = root.get_child(i)
		_find_canvas_layers_recursive(node, canvas_layers)
	
	# Check all found canvas layers for a joystick
	for layer in canvas_layers:
		gui_canvas_layer = layer
		joystick = _find_joystick_in_node(layer)
		if joystick:
			print("Found joystick in CanvasLayer: " + layer.get_path_to(joystick))
			return
	
	# Method 2: Direct path from the root
	var main = get_tree().current_scene
	if main:
		# Try a few common paths
		var possible_paths = [
			"CanvasLayer/TouchScreenJoystick", 
			"GUI/TouchScreenJoystick",
			"UI/TouchScreenJoystick",
			"HUD/TouchScreenJoystick"
		]
		
		for path in possible_paths:
			joystick = main.get_node_or_null(path)
			if joystick:
				print("Found joystick at path: " + path)
				return
	
	# If we reach here, we couldn't find the joystick
	print("WARNING: Could not find joystick in the scene tree")
	
# Helper function to find all CanvasLayers in the scene
func _find_canvas_layers_recursive(node, result_array):
	if node is CanvasLayer:
		result_array.append(node)
	
	for i in range(node.get_child_count()):
		_find_canvas_layers_recursive(node.get_child(i), result_array)

# Helper function to find a joystick within a node
func _find_joystick_in_node(node):
	# Look for a node with "joystick" in its name (case insensitive)
	for i in range(node.get_child_count()):
		var child = node.get_child(i)
		if "joystick" in child.name.to_lower():
			return child
		
		# Recursively search in children
		var found = _find_joystick_in_node(child)
		if found:
			return found
	
	return null

# Update the GUI position relative to the player
func update_gui_position():
	# Check if we have a joystick reference, try to find it if we don't
	if not joystick:
		find_gui()
		if not joystick:
			return
	
	# Only try to set properties if the joystick is a Control node
	if joystick is Control:
		# For Control nodes in a CanvasLayer, we can set their anchors and margins
		
		# Try to set the anchors - use try/catch since not all Control nodes might support these properties
		if joystick.has_method("set_anchors_preset"):
			# Use the preset for bottom-left corner
			joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		else:
			# Manually set anchors if possible
			if "anchor_top" in joystick:
				joystick.anchor_top = 1.0
				joystick.anchor_bottom = 1.0
				joystick.anchor_left = 0.0
				joystick.anchor_right = 0.0
		
		# Set margins if possible
		if "offset_left" in joystick:
			joystick.offset_left = 20
			joystick.offset_right = joystick.offset_left + 150
			joystick.offset_top = -170
			joystick.offset_bottom = -20
		
		# For older Godot versions or custom controls that might use different properties
		if "margin_left" in joystick:
			joystick.margin_left = 20
			joystick.margin_right = 170
			joystick.margin_top = -170
			joystick.margin_bottom = -20
		
		# Backup approach - just set position directly
		joystick.position = Vector2(20, get_viewport_rect().size.y - 170)
		
		# Queue redraw if the method exists
		if joystick.has_method("queue_redraw"):
			joystick.queue_redraw()
	else:
		# For non-Control nodes, we might need a different approach
		# This will depend on what type of node the joystick actually is
		pass
