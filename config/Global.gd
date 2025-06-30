extends Node


var gameStarted: bool

var is_dialog_open := false

func _ready():
	Dialogic.connect("dialog_started", Callable(self, "_on_dialog_started"))
	Dialogic.connect("dialog_ended", Callable(self, "_on_dialog_ended"))

func _on_dialog_started():
	is_dialog_open = true

func _on_dialog_ended():
	is_dialog_open = false
	
var playerBody: CharacterBody2D


var selected_form_index: int

var playerAlive :bool
var playerDamageZone: Area2D
var playerDamageAmount: int
var playerHitbox: Area2D



var telekinesis_mode := false
var camouflage := false
var time_freeze := false


var enemyADamageZone: Area2D
var enemyADamageAmount: int
var enemyAdealing: bool
var enemyAknockback := Vector2.ZERO



# --- Game Settings (These would be explicitly managed and saved/loaded by other systems) ---
var fullscreen_on = false
var vsync_on = false
var master_vol = -10.0
var bgm_vol = -10.0
var sfx_vol = -10.0

# var completed_events[dialogue_id]

# --- NEW: Current Scene Path (CRUCIAL for saving/loading which scene to load) ---
# This variable stores the path to the scene where the game was saved.

# --- NEW: Current Scene Path (CRUCIAL for saving/loading which scene to load) ---
# This variable stores the path to the scene where the game was saved.
var current_scene_path: String = "" 

# --- NEW: Function to gather GLOBAL savable data ---
# This is called by SaveLoadManager.gd to get the global state to save.
func get_save_data() -> Dictionary:
	var data = {
		"current_scene_path": current_scene_path,
		# Add any other global variables you want to save here in the future
		# e.g., "enemies_done": enemies_done,
		# "key_item1": key_item1,
		# ... (other global flags/variables)
	}
	print("Global: Gathering save data for current_scene_path: ", current_scene_path)
	return data

# --- NEW: Function to apply loaded GLOBAL data ---
# This is called by SaveLoadManager.gd to apply the loaded global state.
func apply_load_data(data: Dictionary):
	# Use .get() with a default value for robustness, in case the key doesn't exist in an older save
	current_scene_path = data.get("current_scene_path", "")
	print("Global: Applied loaded current_scene_path: ", current_scene_path)
	# Apply any other loaded global variables here in the future
	# e.g., enemies_done = data.get("enemies_done", false)

# --- NEW: Function to reset global state to default (for New Game or failed load) ---
# This is called when a new game starts or a load fails, to clear previous state.
func reset_to_defaults():
	print("Global: Resetting essential game state to defaults.")
	current_scene_path = ""
	# Reset other global variables to their default initial values here if they are part of save state
	# e.g., is_dialog_open = false
	# e.g., selected_form_index = 0
	# ...
