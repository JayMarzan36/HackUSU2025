extends Node2D

@export var player_scene: PackedScene
@export var player_spawn_position: Vector2 = Vector2(400, 300)

# Store references to be accessible from anywhere
var player_node = null
var farm_node = null

func _ready():
	# Spawn the player
	var player = player_scene.instantiate()
	add_child(player)
	player.position = player_spawn_position
	player_node = player
	
	# Find the farm node
	farm_node = find_child("Farm", true, false)
	if farm_node:
		print("Farm found:", farm_node.name)
	else:
		print("ERROR: Farm node not found!")
	
	# Display controls information
	print("Controls:")
	print("- Arrow keys: Move player")
	print("- Enter: Interact with farm tile in front of you")

# This will be called from the player script
func get_farm():
	return farm_node
