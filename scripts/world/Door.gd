extends Area2D

@export var target_room: String     # Name of the destination room (node or scene)
@export var target_spawn: String    # Name of the spawn marker in the target room

@onready var transition_manager = get_node("/root/TransitionManager")
# (Alternatively, get_node("/root/TransitionManager") if autoloaded, or a NodePath to a TransitionManager node in scene.)

func _ready() -> void:
	# Connect the body_entered signal to trigger the transition when player enters the door area
	self.connect("body_entered", self._on_door_body_entered)
	# (Ensure the collision layer/mask is set so that the player (body) colliding triggers this.)

func _on_door_body_entered(body: Node) -> void:
	if body.name == "Player":  # or `body is Player` if a class
		# Initiate the room transition via the TransitionManager
		transition_manager.travel_to(body, target_room, target_spawn)
