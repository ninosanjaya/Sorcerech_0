extends BaseState
class_name CyberState

var grapple_line: Line2D = null # Line2D node for drawing the grapple rope

# Grapple point stores the global position where the grapple latched on
var grapple_point: Vector2 = Vector2.ZERO
var is_grappling = false # Flag to indicate if grappling is active

var is_swinging = false # Flag to indicate if player is in swing mode (pendulum physics)
var original_rope_length = 0.0 # Stores the initial distance to the grapple point when swing starts

# Preload the Combat FSM for player combat logic
const CombatFSM = preload("res://scripts/player/combat/CombatFSM.gd")
var combat_fsm: CombatFSM
var attack_timer := 0.0 # Timer for managing attack duration (if any)

# === Grapple Mechanics Constants ===

const PULL_SPEED = 200.0        # Base speed at which player is pulled toward grapple point (when not swinging)
const MAX_PULL_SPEED = 500.0    # Maximum speed player can reach when pulled (not currently capped in logic, but useful if added)
const PULL_ACCELERATION = 2000.0 # How quickly the player accelerates toward the grapple point

const MAX_GRAPPLE_DISTANCE = 150.0 # Max distance to detect and attach to a grapple target
const MIN_DISTANCE = 30.0       # If player is closer than this, auto-releases the grapple (not explicitly used for auto-release here)
const SWING_MODE_DISTANCE = 80.0 # When distance is less than this, switch from pull to swing mode
const ANGLE_BOOST_FACTOR = 1.5   # Boost multiplier for momentum when pulled at an angle (not currently used)

const GRAVITY_SCALE = 0.3       # Reduces gravity effect during grappling (lower = floatier, if applied to player.velocity.y manually)

# === Swing Mechanics (Pendulum Physics) ===

var pendulum_angle = 45.0       # Initial angle for visual or potential future use (not actively used in swing calculations here)
var angular_velocity = 0.0      # Speed of swing (angular), increases with input torque
var swing_velocity = Vector2.ZERO # Actual velocity used during swing motion, preserved on release

# **IMPORTANT CHANGE**: PENDULUM_GRAVITY now matches the global GRAVITY constant
const SWING_FORCE = 800.0       # Force applied when moving left/right during grapple (useful for control while pulling)
const PENDULUM_GRAVITY = 1200.0 # Simulated gravity force used in swing calculations. Matches global GRAVITY.
const PENDULUM_DAMPING = 0.93   # Damping applied to angular velocity to simulate swing slowing over time

var swing_angle = 0.0           # Radians, angle from the grapple point (relative to Y-axis)
const SWING_TORQUE = 8.0        # How much input affects angular velocity
const ANGULAR_DAMPING = 0.95    # Damping to prevent perpetual motion in the swing

const GRAVITY = 1200.0          # Global gravity constant, used for consistency

# === Combat Constants ===

const ATTACK_DURATION := 0.2    # Duration the cyber attack state lasts

var wall_jump_force = 200
 
# Constructor for the state
func _init(_player):
	player = _player
	combat_fsm = CombatFSM.new(player)
	# Note: Adding combat_fsm as a child of this state (CyberState) might not be
	# the most conventional pattern. Typically, FSMs are children of the entity
	# they control (e.g., player). If this causes issues, consider restructuring.
	# For now, keeping it as per your original code.
	add_child(combat_fsm)

# Called when entering this state
func enter():
	grapple_line = player.get_node("GrappleLine") # Get the Line2D node for the grapple rope
	Global.playerDamageAmount = 30 # Set player's damage amount (assuming Global is an Autoload)
	print("Entered Cyber State")
	
	 # ... your existing enter() logic for CyberState ...
	print("DEBUG_CYBERSTATE_ENTER: Entered Cyber State.")
	var sprite = player.get_node_or_null("Sprite2D")
	if sprite and sprite.material and (sprite.material is ShaderMaterial):
		# Log the shader uniform when entering CyberState.
		print("DEBUG_CYBERSTATE_ENTER: Shader Alpha Override: ", sprite.material.get_shader_parameter("camouflage_alpha_override"))
	elif sprite:
		print("DEBUG_CYBERSTATE_ENTER: Sprite2D does not have a ShaderMaterial or material is null.")
	else:
		print("DEBUG_CYBERSTATE_ENTER: Sprite2D node not found.")



# Called when exiting this state
func exit():
	# ... your existing exit() logic for CyberState ...
	print("DEBUG_CYBERSTATE_EXIT: Exited Cyber State.")

	release_grapple() # Ensure the grapple is released when leaving the CyberState
	
	player.skill_cooldown_timer.start(0.1)
	player.attack_cooldown_timer.start(0.1)

# Main physics update loop for the state
func physics_process(delta):
	#print(player.velocity.x)
	#print(player.is_on_wall())
	if player.is_on_wall() and Input.is_action_just_pressed("move_up"):
		print("wall jump")
		player.wall_jump_just_happened = true
		player.wall_jump_timer = player.WALL_JUMP_DURATION
		
		if player.facing_direction == 1:
			player.velocity.x += -wall_jump_force
			player.facing_direction = -1
			#player.sprite.flip_h = false
			
			print("move to right, knock to left")
		elif player.facing_direction == -1:
			player.velocity.x += wall_jump_force
			player.facing_direction = 1
			#player.sprite.flip_h = true
			print("move to left, knock to right")
		
		player.velocity.y = -300
		
	
	#else:
	#	player.wall_jump_just_happened = false
		
	combat_fsm.physics_update(delta) # Update the combat finite state machine

	# Handle player abilities (canon/telekinesis)
	if player.canon_enabled == true or player.telekinesis_enabled == true:
		player.velocity = Vector2.ZERO # Stop player movement if these abilities are active
	else:
		player.scale = Vector2(1,1) # Reset player scale

		# Handle cyber attack input
		if Input.is_action_just_pressed("yes") and player.can_attack == true and Global.playerAlive:
			player.AreaAttack.monitoring = true      # Enable monitoring for attack area
			#player.AreaAttackColl.disabled = false   # Enable collision for attack area
			
			
			print("Cyber attacking")

		# Handle grapple input
		if Input.is_action_just_pressed("no") and player.can_skill == true and Global.playerAlive:
			perform_grapple()

	# Handle grapple movement if currently grappling
	if is_grappling:
		handle_grapple_movement(delta)

	# Release grapple if "move_up" (jump) is pressed while grappling
	# Added `and is_grappling` to prevent releasing when not grappling
	if Input.is_action_just_pressed("move_up") and is_grappling:
		release_grapple()

	
# Input handling (currently empty)
func handle_input(event):
	pass

# Initiates the grapple attempt
func perform_grapple():
	var space_state = player.get_world_2d().direct_space_state
	var closest_target: Node2D = null
	var closest_distance := MAX_GRAPPLE_DISTANCE

	# Iterate through all nodes in the "grapple_targets" group
	for target in player.get_tree().get_nodes_in_group("grapple_targets"):
		# Skip if target doesn't have global_position (e.g., not a Node2D or derivate)
		if not target.has_method("get_global_position"):
			continue

		var to_target = target.global_position - player.global_position
		var distance = to_target.length()

		# Skip if target is beyond max grapple distance
		if distance > MAX_GRAPPLE_DISTANCE:
			continue

		var query = PhysicsRayQueryParameters2D.create(player.global_position, target.global_position)
		query.exclude = [player]
		var result = space_state.intersect_ray(query)

		# Only allow grappling if nothing is in the way or the hit is the target itself
		if result.is_empty() or result.collider == target:
			if distance < closest_distance:
				closest_target = target
				closest_distance = distance
		else:
			# Optional: Debug what the ray hits
			print("Blocked by: ", result.collider.name)

	# If a valid grapple target was found
	if closest_target:
		grapple_point = closest_target.global_position # Set the grapple point
		is_grappling = true # Activate grappling

		# Initialize grapple line points if not already set
		if grapple_line.get_point_count() == 0:
			grapple_line.clear_points()
			grapple_line.add_point(Vector2.ZERO) # Origin relative to player
			grapple_line.add_point(player.to_local(grapple_point)) # Grapple point relative to player
		
		print("Grappling to ", grapple_point)
	else:
		print("No visible grapple targets found")
		is_grappling = false

# Handles player movement during grappling (pulling or swinging)
func handle_grapple_movement(delta):
	# Exit if not grappling or grapple line is not set up
	if not is_grappling or grapple_line.get_point_count() < 2:
		return

	# This print statement means that handle_grapple_movement is being called,
	# which is expected every physics frame when grappling is active.
	print("grapp to swing")

	var to_grapple = grapple_point - player.global_position # Vector from player to grapple point
	var distance = to_grapple.length() # Current distance to grapple point
	var direction = to_grapple.normalized() # Normalized direction vector

	# If player is close enough to the grapple point, switch to swing mode
	if distance < SWING_MODE_DISTANCE and not is_swinging:
		# Only switch if player speed is relatively low to prevent jarring transitions
		if player.velocity.length() < 300:
			enter_swing_mode(distance)

	if is_swinging:
		handle_swing_movement(delta) # Handle swing physics
	else:
		# PULL MODE: Player is pulled towards the grapple point
		# Apply acceleration towards the grapple point
		var acceleration = direction * PULL_ACCELERATION * delta
		player.velocity += acceleration
		player.velocity = player.velocity.limit_length(PULL_SPEED) # Limit max pull speed
		player.global_position += player.velocity * delta # Manually update player position
		#player.velocity = direction * PULL_SPEED  # already calculated
		
		# Apply lateral forces for control during pull
		if Input.is_action_pressed("move_left"):
			player.global_position.x -= SWING_FORCE * delta
		elif Input.is_action_pressed("move_right"):
			player.global_position.x += SWING_FORCE * delta

	# Update the visual representation of the grapple rope
	grapple_line.set_point_position(0, Vector2.ZERO) # Rope start at player's origin (local space)
	grapple_line.set_point_position(1, player.to_local(grapple_point)) # Rope end at grapple point (local space)

# Enters the swinging (pendulum) mode
func enter_swing_mode(distance):
	is_swinging = true # Activate swing flag
	original_rope_length = distance # Store the initial rope length

	var to_player = player.global_position - grapple_point # Vector from grapple point to player
	# Calculate initial swing angle. atan2(x, y) gives angle relative to Y-axis.
	swing_angle = atan2(to_player.x, to_player.y)
	angular_velocity = 0.0 # Reset angular velocity on entering swing mode

# Handles player movement during swinging (pendulum physics)
func handle_swing_movement(delta):
	if grapple_point == null: # Should not happen if grappling is true, but good safeguard
		return

	# --- Calculate force and angular momentum ---
	# Calculate gravity torque affecting the pendulum.
	# The `PENDULUM_GRAVITY` constant (now matching `GRAVITY`) is crucial here.
	var gravity_torque = -sin(swing_angle) * PENDULUM_GRAVITY / original_rope_length
	angular_velocity += gravity_torque * delta # Apply gravity's effect to angular velocity

	# --- Input torque from player movement ---
	# Apply player input to angular velocity for left/right swing control
	if Input.is_action_pressed("move_left"):
		angular_velocity -= SWING_TORQUE * delta
	elif Input.is_action_pressed("move_right"):
		angular_velocity += SWING_TORQUE * delta

	# --- Apply damping to avoid infinite swing ---
	angular_velocity *= ANGULAR_DAMPING # Reduce angular velocity over time

	# --- Update swing angle ---
	swing_angle += angular_velocity * delta # Update the angle based on current angular velocity

	# --- Clamp angle within -PI to PI to prevent numerical issues or "flipping" ---
	swing_angle = fmod(swing_angle + PI, TAU) - PI

	# --- Calculate player position around the circle (pendulum arc) ---
	# Calculate the offset from the grapple point based on the current swing angle and rope length
	var offset = Vector2(
		sin(swing_angle), # X component from angle relative to Y-axis
		cos(swing_angle)  # Y component from angle relative to Y-axis
	) * original_rope_length

	player.global_position = grapple_point + offset # Directly set player's global position

	# --- Store tangent velocity for post-release momentum ---
	# Calculate the current tangential velocity of the player along the arc.
	# This velocity will be preserved when the grapple is released.
	var tangent_direction = Vector2(cos(swing_angle), -sin(swing_angle)) # Tangent vector (clockwise for Y-axis angle)
	swing_velocity = tangent_direction * angular_velocity * original_rope_length # Velocity = speed * direction

	# Additionally, set player.velocity for consistency if other states use it immediately.
	player.velocity = swing_velocity

# Releases the grapple
func release_grapple():
	if is_grappling: # Only release if currently grappling
		is_grappling = false
		is_swinging = false
		player.is_grappling = false # Update the player node's own grappling state (if exists)
		grapple_line.clear_points() # Clear the visible grapple rope

		# Preserve the calculated swing velocity so the player continues with momentum
		player.velocity = swing_velocity
