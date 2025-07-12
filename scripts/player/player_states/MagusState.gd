extends BaseState

class_name MagusState

var combat_fsm: CombatFSM


const CombatFSM = preload("res://scripts/player/combat/CombatFSM.gd")


var is_attacking := false
var attack_timer := 0.0
const ATTACK_DURATION := 0.2  # seconds


# We no longer need _camouflage_target_modulate as a Color,
# just the alpha value (transparency) we want to pass to the shader.
var _camouflage_target_alpha: float = 1.0 # Default to opaque (1.0)

var _sprite_node: Sprite2D = null
var _animation_player_node: AnimationPlayer = null

# Variable to store the original material of the Sprite2D node.
# This will allow us to restore it when exiting MagusState.
var _original_sprite_material: Material = null
var _camouflage_shader_material: ShaderMaterial = null



func _init(_player):
	player = _player
	combat_fsm = CombatFSM.new(player)
	add_child(combat_fsm)

func enter():
	Global.playerDamageAmount = 20
	
	_sprite_node = player.get_node_or_null("Sprite2D")
	if not _sprite_node:
		push_warning("MagusState: 'Sprite2D' child node not found on player. Camouflage won't work.")
		return # Exit early if sprite is essential

	# Store the Sprite2D's current material before applying our shader.
	# This ensures we can restore it when MagusState exits.
	_original_sprite_material = _sprite_node.material

	# Create a new instance of our ShaderMaterial if it hasn't been created yet.
	# We do this here to avoid creating it every time 'enter' is called unnecessarily.
	if not _camouflage_shader_material:
		var shader_resource = load("res://shaders/camouflage_alpha.gdshader") # Ensure this path is correct!
		if not shader_resource:
			push_error("MagusState: 'camouflage_alpha.gdshader' not found at the specified path. Camouflage will not work.")
			return

		_camouflage_shader_material = ShaderMaterial.new()
		_camouflage_shader_material.shader = shader_resource

	# Apply our ShaderMaterial to the Sprite2D.
	_sprite_node.material = _camouflage_shader_material

	# Check if the Sprite2D now has our ShaderMaterial applied. This is crucial for the shader approach.
	if not (_sprite_node.material is ShaderMaterial):
		push_error("MagusState: Failed to apply ShaderMaterial to Sprite2D! Camouflage will not work.")
		return


	_animation_player_node = player.get_node_or_null("AnimationPlayer")
	if not _animation_player_node:
		_animation_player_node = _sprite_node.get_node_or_null("AnimationPlayer")
	if not _animation_player_node:
		push_warning("MagusState: 'AnimationPlayer' node not found. Debugging might be less insightful.")


	# Initialize the camouflage target alpha based on the player's current state.
	if player.allow_camouflage:
		_camouflage_target_alpha = 0.5 # Semi-transparent for camouflage
	else:
		_camouflage_target_alpha = 1.0 # Fully opaque otherwise

	# Set the shader uniform directly on enter
	if _sprite_node.material: # Ensure material exists before trying to set uniform
		_sprite_node.material.set_shader_parameter("camouflage_alpha_override", _camouflage_target_alpha)

	#print("DEBUG_ENTER: Initial camouflage_alpha_override: ", _camouflage_target_alpha)
	#print("DEBUG_ENTER: player.allow_camouflage initial state: ", player.allow_camouflage)
	print("Entered Magus State. ShaderMaterial applied.")


func exit():
	if _sprite_node:
		# Reset the shader uniform to fully opaque before removing the shader.
		if _sprite_node.material and (_sprite_node.material is ShaderMaterial):
			_sprite_node.material.set_shader_parameter("camouflage_alpha_override", 1.0)
			#print("DEBUG_EXIT: camouflage_alpha_override reset to: 1.0")

		# Restore the original material to the Sprite2D.
		# This allows other states to use default rendering or their own materials.
		_sprite_node.material = _original_sprite_material
		#print("DEBUG_EXIT: Restored original Sprite2D material.")
	else:
		print("DEBUG_EXIT: Sprite node not found, cannot reset material.")
	#print("DEBUG_EXIT: player.allow_camouflage on exit: ", player.allow_camouflage)
	print("Exited Magus State.")

	_camouflage_target_alpha = 1.0 # Fully opaque
	_sprite_node.material.set_shader_parameter("camouflage_alpha_override", _camouflage_target_alpha) # Apply immediately
	Global.camouflage = false
	player.allow_camouflage = false
	print("Camouflage OFF")
	
	player.skill_cooldown_timer.start(0.1)
	player.attack_cooldown_timer.start(0.1)

func physics_process(delta):
	combat_fsm.physics_update(delta)
	
	if player.canon_enabled == true or player.telekinesis_enabled == true:
		player.velocity = Vector2.ZERO
	else:
		player.scale = Vector2(1,1)
		
		if Input.is_action_just_pressed("yes") and player.can_attack == true and Global.playerAlive:
			player.shoot_fireball() # Call the new function to shoot a fireball
			#player.can_attack = false # Apply attack cooldown
			#player.attack_cooldown_timer.start(player.attack_cooldown_timer.wait_time) # Use the timer's set wait_time
			print("Magus shooting fireball!")
			# The following lines are for melee attack and should be removed or commented out:
			# player.AreaAttack.monitoring = true
			# player.AreaAttackColl.disabled = false
			
		if Input.is_action_just_pressed("no") and player.can_skill == true and Global.playerAlive:
			toggle_camouflage()
	
	# Your existing physics logic goes here.
	# The camouflage transparency is now managed by continuously setting the shader uniform.

	# Only proceed if sprite and our ShaderMaterial are applied.
	# If _sprite_node.material is not _camouflage_shader_material, it means
	# MagusState's shader is not active, so we don't try to control its uniform.
	if not _sprite_node or not _sprite_node.material or not (_sprite_node.material is ShaderMaterial):
		# We might be in a state where the shader is not active (e.g., CyberState)
		# In this case, we don't control the alpha.
		return # Exit early if our shader is not active.

	# DEBUG: Log the modulate. This should now correctly show the AnimationPlayer's color (if set).
	#print("DEBUG_PHYSICS_PROCESS_CURRENT_MODULATE: Sprite Modulate (from AP/default): ", _sprite_node.modulate)
	# DEBUG: Check if AnimationPlayer is playing and what it's animating.
	#if _animation_player_node and _animation_player_node.is_playing():
	#	print("DEBUG_PHYSICS_PROCESS: AnimationPlayer is playing: ", _animation_player_node.current_animation)

	# === Camouflage Alpha Override (via Shader Uniform) ===
	# This continuously sets the shader uniform ONLY IF MagusState's shader is active.
	if player.allow_camouflage:
		_sprite_node.material.set_shader_parameter("camouflage_alpha_override", _camouflage_target_alpha)
		#print("DEBUG_PHYSICS_PROCESS_AFTER_OVERRIDE: Camouflage ON. Shader Alpha FORCED to: ", _camouflage_target_alpha)
	else:
		# When camouflage is OFF, ensure the shader uniform is 1.0 (fully opaque).
		# We still need to force it here because we're always controlling transparency via shader
		# while MagusState is active.
		_sprite_node.material.set_shader_parameter("camouflage_alpha_override", _camouflage_target_alpha)
		#print("DEBUG_PHYSICS_PROCESS_CAMOUFLAGE_OFF: Camouflage OFF. Shader Alpha set to: ", _camouflage_target_alpha)


	# === Camouflage Modulate Override ===
	# This is the core logic to prioritize the camouflage visual.
	# If camouflage is active, we continuously force the Sprite2D's modulate
	# to the desired semi-transparent camouflage color. This will override
	# any modulate values set by an AnimationPlayer that might be running.
	#if player.allow_camouflage:
	#	player.get_node("Sprite2D").modulate = _camouflage_target_modulate
	# ELSE: If camouflage is OFF, we do *nothing* in physics_process regarding
	# the sprite's modulate. This allows the AnimationPlayer (or any other
	# system) to freely control the Sprite2D's modulate property without
	# interference from this state. The 'toggle_camouflage' function will
	# handle setting it back to opaque when the ability is turned off.
	


func handle_input(event):
	pass

func toggle_camouflage():
	player.allow_camouflage = not player.allow_camouflage

	if not _sprite_node or not _sprite_node.material or not (_sprite_node.material is ShaderMaterial):
		# This warning is less critical now, as the material might legitimately not be our shader.
		push_warning("toggle_camouflage: Sprite2D node, its material, or ShaderMaterial not found/applied.")
		return

	#print("DEBUG_TOGGLE: toggle_camouflage called. player.allow_camouflage changed to: ", player.allow_camouflage)

	if player.allow_camouflage:
		_camouflage_target_alpha = 0.5 # Semi-transparent
		_sprite_node.material.set_shader_parameter("camouflage_alpha_override", _camouflage_target_alpha) # Apply immediately
		#print("DEBUG_TOGGLE: Camouflage ON logic applied. Shader Alpha set to: ", _camouflage_target_alpha)
		print("Camouflage ON - enemies ignore the player")
		Global.camouflage = true
		
		await player.get_tree().create_timer(5.0).timeout
		
		_camouflage_target_alpha = 1.0 # Fully opaque
		_sprite_node.material.set_shader_parameter("camouflage_alpha_override", _camouflage_target_alpha) # Apply immediately
		#print("DEBUG_TOGGLE: Camouflage OFF logic applied. Shader Alpha set to: ", _camouflage_target_alpha)
		print("Camouflage OFF")
		player.allow_camouflage = !player.allow_camouflage
		Global.camouflage = false
		
