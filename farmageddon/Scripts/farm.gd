extends Node2D

@onready var tilemap = $FarmTileMap

# Dictionary to track tile states
var tile_states = {}

# Store source IDs based on your debug output
var GRASS_SOURCE_ID = 0
var HILLS_SOURCE_ID = 1
var TILLED_DIRT_SOURCE_ID = 2
var TILLED_DIRT_WATERED_SOURCE_ID = 3
var WATER_SOURCE_ID = 4

# Use tile coordinate (2, 2) for both tilled and watered dirt
var TILLED_DIRT_COORD = Vector2i(0, 5)
var WATERED_DIRT_COORD = Vector2i(2, 2)

# Make sure to use the highest layer for farming tiles
var BASE_LAYER = 0       # For grass, hills, water
var FARMING_LAYER = 1    # For tilled and watered soil

# Flag to toggle farm input processing
var farm_mode_active = false  # Set to false by default so joystick works

func _ready():
	print("Farm script starting - with farming tiles on top layer")
	
	# Get the number of layers to ensure we're using the highest one
	var layer_count = tilemap.get_layers_count()
	if layer_count > 1:
		FARMING_LAYER = layer_count - 1  # Use the highest available layer
		print("Using layer", FARMING_LAYER, "for farming tiles")
	
	# Initialize the tile_states dictionary based on the existing tilemap
	initialize_tile_states()

func initialize_tile_states():
	# Get the size of the tilemap (you may need to adjust these values)
	var map_width = 30
	var map_height = 30
	
	for x in range(map_width):
		for y in range(map_height):
			var pos = Vector2i(x, y)
			var source_id = tilemap.get_cell_source_id(BASE_LAYER, pos)
			
			# If this is a grass tile, mark it as farmable
			if source_id == GRASS_SOURCE_ID:
				tile_states[pos] = "grass"
			
			# Check if there's already something on the farming layer
			var farming_source = tilemap.get_cell_source_id(FARMING_LAYER, pos)
			if farming_source == TILLED_DIRT_SOURCE_ID:
				tile_states[pos] = "tilled"
			elif farming_source == TILLED_DIRT_WATERED_SOURCE_ID:
				tile_states[pos] = "watered"
	
	print("Initialized with", tile_states.size(), "tracked tiles")

# Functions for player interaction
func till_soil(map_position):
	if map_position in tile_states and tile_states[map_position] == "grass":
		# Place tilled dirt on the farming layer
		tilemap.set_cell(FARMING_LAYER, map_position, TILLED_DIRT_SOURCE_ID, TILLED_DIRT_COORD)
		tile_states[map_position] = "tilled"
		print("Tilled soil at", map_position, "on layer", FARMING_LAYER)
		return true
	return false

func water_soil(map_position):
	if map_position in tile_states and tile_states[map_position] == "tilled":
		# Place watered dirt on the farming layer
		tilemap.set_cell(FARMING_LAYER, map_position, TILLED_DIRT_WATERED_SOURCE_ID, WATERED_DIRT_COORD)
		tile_states[map_position] = "watered"
		print("Watered soil at", map_position, "on layer", FARMING_LAYER)
		return true
	return false

# Function to handle player interactions with the farm
func _on_player_use_tool(tool_type, world_position):  # Fixed function name
	# Convert world position to map coordinates
	var map_position = tilemap.local_to_map(tilemap.to_local(world_position))
	
	# Perform the appropriate action based on the tool
	match tool_type:
		"hoe":
			till_soil(map_position)
		"watering_can":
			water_soil(map_position)

# Process input for testing - now with conditional execution
func _unhandled_input(event):  # Changed from _input to _unhandled_input
	# Only process farm inputs if farm mode is active
	if not farm_mode_active:
		return  # Skip processing if farm mode is inactive
		
	# Check for mouse clicks
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Convert mouse position to tile position
		var mouse_pos = get_global_mouse_position()
		var map_pos = tilemap.local_to_map(tilemap.to_local(mouse_pos))
		
		print("Clicked at position:", map_pos)
		
		# Check what's at this position
		if map_pos in tile_states:
			var current_state = tile_states[map_pos]
			print("Current state:", current_state, "at layer", FARMING_LAYER)
			
			# Cycle through states: grass -> tilled -> watered
			if current_state == "grass":
				if till_soil(map_pos):
					print("Tilled the soil!")
			elif current_state == "tilled":
				if water_soil(map_pos):
					print("Watered the soil!")
			elif current_state == "watered":
				print("Already watered!")
		else:
			print("Not a farmable tile")
			
		# Accept the event to prevent it from propagating
		get_viewport().set_input_as_handled()

# Methods to toggle farm mode
func activate_farm_mode():
	farm_mode_active = true
	print("Farm mode activated")
	
func deactivate_farm_mode():
	farm_mode_active = false
	print("Farm mode deactivated")
