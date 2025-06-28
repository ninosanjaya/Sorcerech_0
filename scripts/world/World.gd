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



func _ready() -> void:
	print("World ready. Initializing sandbox...")
	
	#Dialogic.start("timeline1", false)

	#add_child(new_dialog)
	 # Safely enable Camera2D if it exists under the player
	

