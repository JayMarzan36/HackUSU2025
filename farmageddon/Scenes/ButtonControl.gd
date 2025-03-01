extends Control

var tools = {"empty" : [0.0],"hoe" : [0.0], "waterCan" : [0.0], "axe" : [0.0]}
@onready var player = $"res://Scenes/Player.tscn"
@onready var actionButton = $ActionButton
@onready var dropButton = $DropButton

var playerItem = tools.get("empty")
# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#if player.currentTool != null:
		#playerItem = tools.get(player.currentTool)
		#if playerItem == null:
			#print("Player Item Null")
	#pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#if player.currentTool != playerItem:
		## Players item has changed
		#playerItem = player.currentTool
		#
		#actionButton.icon = "hoe"
	#pass
