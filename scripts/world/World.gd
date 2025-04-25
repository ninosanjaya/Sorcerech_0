# World.gd - Simple Sandbox World Script for testing Player
extends Node2D

@onready var player = $Player
@onready var floor = $Floor

func _ready() -> void:
	print("World ready. Initializing sandbox...")
	Dialogic.start("timeline1", false)
	#add_child(new_dialog)
	 # Safely enable Camera2D if it exists under the player
	if $Player.has_node("Camera2D"):
		var cam = $Player.get_node("Camera2D")
		if cam is Camera2D:
			cam.make_current()

	# Optional: Display sandbox label
	if has_node("Label"):
		$Label.text = "Welcome to the Platformer Sandbox!"

	# Enable some test abilities for sandbox
	# Toggle player abilities for testing
	if has_node("Player"):
		$Player.allow_double_jump = true
		$Player.allow_dash = true
		$Player.allow_wall_climb = true

	# Add a static floor platform if not already present

	if floor == null:
		var platform = StaticBody2D.new()
		var shape = CollisionShape2D.new()
		shape.shape = RectangleShape2D.new()
		shape.shape.extents = Vector2(400, 20)  # 800x40 size platform
		platform.position = Vector2(0, 300)
		platform.add_child(shape)

		var sprite = Sprite2D.new()
		sprite.texture = load("res://icon.svg")
		sprite.scale = Vector2(5, 0.2)
		sprite.position = Vector2(0, 0)
		platform.add_child(sprite)

		add_child(platform)


