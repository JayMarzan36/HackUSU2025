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

# Dictionary to define which tile types are walkable
var walkable_tiles = {
	"grass": true,
	"tilled": true,
	"watered": true,
	"water": false,
	"hills": false,
	"none": false  # Default for undefined tiles
}

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
			
			# Categorize base tiles
			if source_id == GRASS_SOURCE_ID:
				tile_states[pos] = "grass"
			elif source_id == HILLS_SOURCE_ID:
				tile_states[pos] = "hills"
			elif source_id == WATER_SOURCE_ID:
				tile_states[pos] = "water"
			elif source_id == -1:  # No tile
				tile_states[pos] = "none"
			
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
func on_player_interaction(world_position):
	# This is a simpler, more direct approach that doesn't rely on complex coordinate conversions
	var map_position = tilemap.local_to_map(tilemap.to_local(world_position))
	
	print("Interaction at map position:", map_position)
	
	# Check if this position is in our tile_states dictionary
	if map_position in tile_states:
		var current_state = tile_states[map_position]
		print("Current tile state:", current_state)
		
		# Handle based on current state
		if current_state == "grass":
			if till_soil(map_position):
				print("Successfully tilled soil at", map_position)
		elif current_state == "tilled":
			if water_soil(map_position):
				print("Successfully watered soil at", map_position)
		elif current_state == "watered":
			print("Tile is already watered")
	else:
		print("Not a farmable tile at", map_position)

# Alternative function that directly takes a map position instead of world position
func interact_at_tile(map_position: Vector2i):
	print("Direct interaction at map position:", map_position)
	
	if map_position in tile_states:
		var current_state = tile_states[map_position]
		print("Current tile state:", current_state)
		
		if current_state == "grass":
			if till_soil(map_position):
				print("Successfully tilled soil at", map_position)
		elif current_state == "tilled":
			if water_soil(map_position):
				print("Successfully watered soil at", map_position)
		elif current_state == "watered":
			print("Tile is already watered")
	else:
		print("Not a farmable tile at", map_position)

# New function to check if a tile is walkable
func is_tile_walkable(map_position: Vector2i) -> bool:
	# Handle out-of-bounds
	if not map_position in tile_states:
		return false
		
	# Get the current state of this tile
	var tile_state = tile_states[map_position]
	
	# Return whether this tile type is walkable
	if tile_state in walkable_tiles:
		return walkable_tiles[tile_state]
	else:
		return false

# Function to check if player can move to a position
func can_move_to(world_position: Vector2) -> bool:
	var map_position = tilemap.local_to_map(tilemap.to_local(world_position))
	return is_tile_walkable(map_position)

# Function to validate player movement (for character controller)
func validate_movement(from_position: Vector2, to_position: Vector2) -> Vector2:
	# Check if destination is walkable
	if can_move_to(to_position):
		return to_position
	else:
		# If not walkable, return the original position
		return from_position

# Optional: Debug visualization for walkable vs non-walkable tiles
func debug_draw_walkable_overlay():
	var map_width = 30
	var map_height = 30
	
	for x in range(map_width):
		for y in range(map_height):
			var pos = Vector2i(x, y)
			
			# Skip tiles that don't exist in our states
			if not pos in tile_states:
				continue
				
			# Define colors for walkable and non-walkable
			var walkable_color = Color(0, 1, 0, 0.3)  # Green with transparency
			var non_walkable_color = Color(1, 0, 0, 0.3)  # Red with transparency
			
			# Get world position of this tile
			var world_pos = tilemap.map_to_local(pos)
			
			# Draw appropriately colored rectangle
			var rect = Rect2(world_pos - Vector2(16, 16), Vector2(32, 32))
			if is_tile_walkable(pos):
				draw_rect(rect, walkable_color)
			else:
				draw_rect(rect, non_walkable_color)

# Override _draw to visualize walkable tiles
func _draw():
	if OS.is_debug_build():  # Only in debug builds
		debug_draw_walkable_overlay()
