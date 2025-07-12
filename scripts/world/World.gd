# World.gd - Simple Sandbox World Script for testing Player
extends Node2D
# The main world scene containing all rooms
#1.Hub starting point (shop, teleport, npcs, etc)
#2.Get form in Magus/Cyber town,1,2,3 (no boss)
#3.Hub for boss for part 1 & start part 2
#4.Get new form in Magus/Cyber town,1,2,3,4,5,Boss (2 type of boss)
#5.Normal ending choose Cyber or Magus at Magus/Cyber town, through connecting 1,2,boss cyber/magus (fight final boss part 2) 
#6.True ending at hidden town, true 1,2,3,final true boss (fight final boss of the game)
#


#Sub scene:
#0. player & enemy
#1. save spot & door/teleport spot
#2. canon spot & bounce spot
#3. telekinesis/switch spot & telekinesis object
#4. telekinesis lock check spot
#5. grappling hook
@onready var cutscene_manager = $CutsceneManager

#func _ready():
	#cutscene_manager.start_cutscene()
	#if Global.play_intro_cutscene:
	#	Global.play_intro_cutscene = false
	##	cutscene_manager.start_cutscene()
#extends Node2D # Or whatever your World scene extends

@onready var player_spawn_point_initial: Marker2D = $Marker2D # A temporary spawn point for the camera during the cutscene
@onready var player_spawn_point_junkyard: Marker2D = $Room_AerendaleJunkyard/Marker2D # The actual player spawn point after the cutscene
#@onready var cutscene_manager: Node = $CutsceneManager # Path to your CutsceneManager node within the World scene
@onready var player_scene: PackedScene = preload("res://scenes/player/player.tscn") # Your player scene

var player_instance: CharacterBody2D = null # To hold the spawned player

func _ready():
	# If this is a new game (from main menu)
	if Global.play_intro_cutscene:
		# Hide player initially and disable input
		if player_instance:
			player_instance.visible = false
			# You might need a way to disable player input/movement here
			# e.g., player_instance.set_process_input(false) or a global flag

		# Position camera for the cutscene. This assumes your camera follows the player.
		# If your camera is a separate node, you'd move the camera directly.
		# For a more robust solution, consider a dedicated CutsceneCamera.
		if player_spawn_point_initial:
			get_viewport().get_camera_2d().global_position = player_spawn_point_initial.global_position
			get_viewport().get_camera_2d().zoom = Vector2(1,1) # Reset zoom if needed for cutscene

		# Connect to the cutscene finished signal
		if cutscene_manager and cutscene_manager.has_method("start_cutscene"):
			cutscene_manager.cutscene_finished.connect(_on_cutscene_manager_finished)
			cutscene_manager.start_cutscene()
		else:
			# Fallback if cutscene manager isn't found or callable
			print("❌ CutsceneManager not found or 'start_cutscene' method missing. Spawning player immediately.")
			spawn_player_at_junkyard()
   # else:
		# If not a new game (e.g., loaded game), spawn player normally
		#spawn_player_at_junkyard()

func _on_cutscene_manager_finished():
	print("World: CutsceneManager finished signal received.")
	Global.play_intro_cutscene = false # Reset flag

	spawn_player_at_junkyard()
	# Re-enable player input/visibility after cutscene
	if player_instance:
		player_instance.visible = true
		# player_instance.set_process_input(true)
	# Consider fading back in from black after the cutscene finishes and player is positioned
	# (Your cutscene manager already handles a fade out, so this might not be strictly necessary here)

func spawn_player_at_junkyard():
	if not player_instance:
		player_instance = player_scene.instantiate()
		add_child(player_instance)
		print("Player instantiated and added to World.")

	if player_spawn_point_junkyard:
		player_instance.global_position = player_spawn_point_junkyard.global_position
		print("✅ Player positioned at junkyard spawn point.")
		# If your camera follows the player, it will now move to the player's position.
	else:
		print("❌ Junkyard spawn point not found!")
