# Player.gd - Player character script
extends CharacterBody2D

# — Player constants and exported properties —
@export var move_speed: float = 300.0   # Walking speed in pixels/sec
@export var jump_force: float = 500.0   # Jump impulse force (vertical velocity for jump)
@export var gravity: float = 1200.0     # Gravity strength (pixels/sec^2)

# Ability toggles (exported for easy tweaking in editor):
@export var allow_double_jump: bool = false
@export var allow_dash: bool = false
@export var allow_wall_climb: bool = false
@export var allow_melee: bool = false
@export var allow_pistol: bool = false
@export var allow_rocket: bool = false
@export var allow_grappling_hook: bool = false
@export var allow_camouflage: bool = false
@export var allow_invincibility: bool = false
@export var allow_laser: bool = false
@export var allow_teleport: bool = false
@export var allow_clones: bool = false
@export var allow_swimming: bool = false
@export var allow_flying: bool = false
@export var allow_flying2_area: bool = false
@export var allow_digging: bool = false
@export var allow_digging2_area: bool = false
@export var allow_time_freeze: bool = false
@export var allow_magnet: bool = false
@export var allow_stat_upgrades: bool = false

# Movement state
#var velocity: Vector2 = Vector2.ZERO    # The player's current velocity
var facing_direction: int = 1           # 1 for facing right, -1 for facing left (used for shooting, etc.)

# Jump state for double jump
var jumps_available: int = 1            # How many jumps left before landing (1 = normal single jump; 2 if double jump allowed)

# Dash state
var is_dashing: bool = false
var dash_time_left: float = 0.0
const DASH_DURATION: float = 0.2        # seconds for a dash move
const DASH_SPEED: float = 600.0         # speed during dash (faster than normal move_speed)

# Invincibility and camouflage state
var invincible: bool = false
var camouflage_on: bool = false

# Time freeze state
var time_frozen: bool = false

# Ability resources (preloaded scenes for projectiles, clones, etc.)
# In a real project, you would have separate scene files for bullets, rockets, clones.
# Here we assume they exist at given paths for demonstration.
#var BulletScene = preload("res://Bullet.tscn")      # simple bullet for pistol
#var RocketScene = preload("res://HomingRocket.tscn")# homing rocket projectile
#var CloneScene = preload("res://PlayerClone.tscn")  # a clone of the player (could be a simpler NPC)

# Placeholder preloads (update these paths with actual resources in your project)
var BulletScene = null
var RocketScene = null
var CloneScene = null

# Form control
const ALL_FORMS := {
	"Normal": {},
	"Magus": {},
	"Cyber": {},
	"UltimateMagus": {},
	"UltimateCyber": {}
}

var unlocked_forms: Array = ["Normal"]
var current_form_index := 0

#const FORM_NAMES := ["Normal", "Magus", "Cyber", "UltimateMagus", "UltimateCyber"]

# Called when the node enters the scene tree (initialization)
func _ready() -> void:
	# Optionally initialize anything or set up defaults.
	#$Player.unlock_form("Magus")
	unlock_form("Magus")
	unlock_form("Cyber")
	#unlock_form("UltimateMagus")
	#unlock_form("UltimateCyber")
	current_form_index = 0  # Start in Normal form
	update_form_abilities()
	jumps_available = 2 if allow_double_jump else 1
	# If camouflage or invincibility start active (usually false by default).
	if allow_camouflage:
		camouflage_on = false
	if allow_invincibility:
		invincible = false
	# Preload assets safely (update to correct paths when available)
	#if ResourceLoader.exists("res://Bullet.tscn"):
	 #   BulletScene = preload("res://Bullet.tscn")
	#if ResourceLoader.exists("res://HomingRocket.tscn"):
	 #   RocketScene = preload("res://HomingRocket.tscn")
	#if ResourceLoader.exists("res://PlayerClone.tscn"):
	 #   CloneScene = preload("res://PlayerClone.tscn")
	
	# Add placeholder sprite if not already present
	if not has_node("Sprite2D"):
		var sprite = Sprite2D.new()
		sprite.texture = load("res://icon.svg")
		add_child(sprite)
		sprite.z_index = 1


# Physics processing: movement and abilities
func _physics_process(delta: float) -> void:
	## 1. GRAVITY AND BASIC MOVEMENT ##
	# Apply gravity if not on floor (falling down).
	if not is_on_floor():
		# If swimming and in water, gravity might be reduced; for simplicity, if allow_swimming is on, use half gravity when in water.
		# (Determining if in water would usually involve an Area2D for water; here we assume if swimming ability is on, gravity is lighter.)
		if allow_swimming:
			velocity.y += gravity * 0.3 * delta  # reduced gravity in water
		else:
			velocity.y += gravity * delta
	else:
		# On floor, reset jump count and end certain states if needed
		jumps_available = 2 if allow_double_jump else 1 # reset double jump when landed&#8203;:contentReference[oaicite:7]{index=7}
		is_dashing = false  # touching ground cancels dash
		# If digging ability is on and player is on diggable ground, we could allow digging here (placeholder).
		if allow_digging and allow_digging2_area: 
			#dig()
			print("digging placeholder")

	# Horizontal movement input
	var direction: float = 0.0
	if Input.is_action_pressed("move_left"):
		direction -= 1.0
	if Input.is_action_pressed("move_right"):
		direction += 1.0
	# Set horizontal velocity
	if not is_dashing:
		if direction != 0:
			velocity.x = direction * move_speed
			facing_direction = sign(direction)  # update facing direction
		else:
			# No input; apply friction (smooth stop)
			velocity.x = move_toward(velocity.x, 0, move_speed * 2 * delta)
	# If dashing, we ignore regular input (player continues dashing in set direction)
	


	## 2. JUMPING (Single/Double) ##
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			# Normal jump
			velocity.y = -jump_force
			jumps_available -= 1  # one jump used (for double jump tracking)
		elif allow_double_jump and jumps_available > 0:
			# Double jump: allowed if we have jumps left and we're not on the floor
			velocity.y = -jump_force
			jumps_available -= 1  # use up the second jump

	## 3. DASH ##
	if allow_dash:
		if Input.is_action_just_pressed("dash") and not is_dashing:
			# Start a dash
			is_dashing = true
			dash_time_left = DASH_DURATION
			# Set dash velocity in facing direction, keep only horizontal component for dash
			velocity.y = 0  # cancel any vertical velocity during dash (optional)
			velocity.x = facing_direction * DASH_SPEED

	# If currently dashing, count down the dash duration
	if is_dashing:
		dash_time_left -= delta
		if dash_time_left <= 0:
			is_dashing = false  # end dash after duration
			

	## 4. WALL CLIMB ##
	if allow_wall_climb:
		# Check if the player is on a wall (Godot provides is_on_wall())&#8203;:contentReference[oaicite:8]{index=8}
		if is_on_wall() and not is_on_floor():
			# If pressing up while on a wall, move up instead of down (climb)
			if Input.is_action_pressed("move_up"):
				velocity.y = -move_speed * 0.5  # climb up at half speed
			else:
				# If not climbing, maybe just stick to wall (reduce sliding)
				velocity.y = min(velocity.y, 100)  # limit fall speed while on wall
		# Optionally, if pressing jump while wall-clinging, perform a wall jump (leap away from wall)
		if is_on_wall():
			velocity.y = -jump_force
			velocity.x = -facing_direction * move_speed
			# This makes the player jump off the wall in opposite horizontal direction.

	## 5. FLYING ##
	if allow_flying:
		# If flying is enabled, allow the player to fly when a key is held (e.g., "jump" or a separate "fly" action)
		#if Input.is_action_pressed("move_up"):
			# Cancel gravity and allow vertical control
		if allow_flying2_area == true:
			velocity.y = 0
			if Input.is_action_pressed("move_up"):
				velocity.y = -move_speed  # move up
			elif Input.is_action_pressed("move_down"):
				velocity.y = move_speed   # move down

	## 6. SWIMMING ##
	# (Basic swimming can be treated as a form of flying while in water; actual water detection not shown.)
	# If swimming ability is on, presumably the player is in water, gravity was already reduced above.

	## 7. ATTACKS & ABILITIES ##
	# Melee attack
	if allow_melee and Input.is_action_just_pressed("z"):
		perform_melee_attack()
	# Pistol shooting
	if allow_pistol and Input.is_action_just_pressed("z"):
		shoot_bullet()
	# Homing rocket
	if allow_rocket and Input.is_action_just_pressed("z"):
		shoot_homing_rocket()
	# Laser (continuous beam) - could be if key is pressed, keep firing
		
	if allow_laser and Input.is_action_pressed("z"):
		fire_laser_beam(delta)

	# Grappling hook
	if allow_grappling_hook and Input.is_action_just_pressed("x"):
		use_grappling_hook()

	# Clones - spawn a clone when ability used
	#if allow_clones and Input.is_action_just_pressed("spawn_clone"):
	#	spawn_clone()

	# Teleport (with objects or to location)
	if allow_teleport and Input.is_action_just_pressed("x"):
		use_teleport()

	# Camouflage (toggle on/off)
	if allow_camouflage and Input.is_action_just_pressed("x"):
		camouflage_on = !camouflage_on
		if camouflage_on:
			$Sprite2D.modulate = Color(1,1,1,0.5)  # make sprite semi-transparent as visual cue
			print("Camouflage ON - enemies ignore the player")
		else:
			$Sprite2D.modulate = Color(1,1,1,1)    # back to opaque
			print("Camouflage OFF")

	# Invincibility (toggle on/off, or could be time-limited)
	#if allow_invincibility and Input.is_action_just_pressed("toggle_invincibility"):
	#	invincible = !invincible
	#	if invincible:
	#		print("Invincibility ON - player won't take damage")
	#	else:
	#		print("Invincibility OFF")

	# Time freeze (toggle time_frozen state)
	if allow_time_freeze and Input.is_action_just_pressed("x"):
		time_frozen = !time_frozen
		if time_frozen:
			print("Time Frozen - enemies paused")
			# In a real game, you might set Engine.time_scale = 0 or pause enemy nodes.
		else:
			print("Time Resumed - enemies active")
			# Reset time_scale or unpause enemies.

	# Magnetism (could be passive; here we simulate when toggled)
	#if allow_magnet and Input.is_action_just_pressed("toggle_magnet"):
		# This ability might constantly pull items when on; here just a toggle message
	#	var status = "ON" if allow_magnet else "OFF"
	#	print("Magnetism toggled: %s" % status)
		
		# (If active, you'd continuously attract nearby pickup nodes toward the player)

	## 8. MOVE THE PLAYER ##
	# Rotate forms
	if Input.is_action_just_pressed("form_next"):
		current_form_index = (current_form_index + 1) % unlocked_forms.size()
		print("Selected form:", unlocked_forms[current_form_index])
	if Input.is_action_just_pressed("form_prev"):
		current_form_index = (current_form_index - 1 + unlocked_forms.size()) % unlocked_forms.size()
		print("Selected form:", unlocked_forms[current_form_index])
	if Input.is_action_just_pressed("form_apply"):
		update_form_abilities()
		print("Form changed to:", unlocked_forms[current_form_index])

	move_and_slide()
# Continue Player.gd - Ability helper functions
func update_form_abilities():
		var form = unlocked_forms[current_form_index]
		# Reset all abilities
		#allow_double_jump = false
		#allow_dash = false
		#allow_wall_climb = false
		allow_camouflage = false
		allow_melee = false
		allow_pistol = false
		allow_rocket = false
		allow_grappling_hook = false
		allow_laser = false
		allow_teleport = false
		allow_clones = false
		allow_swimming = false
		allow_flying = false
		allow_digging = false
		allow_time_freeze = false

		match form:
			"Normal":
				scale = Vector2(0.75, 0.75)
			"Magus":
				allow_pistol = true
				allow_camouflage = true
				scale = Vector2(1, 1)
			"Cyber":
				allow_melee = true
				allow_grappling_hook = true
				scale = Vector2(1, 1)
			"UltimateMagus":
				allow_melee = true
				allow_teleport = true
				allow_digging = true
				scale = Vector2(1.2, 1.2)
			"UltimateCyber":
				#allow_rocket = true
				allow_laser = true
				allow_time_freeze = true
				allow_flying = true
				scale = Vector2(1.2, 1.2)
			_:
				scale = Vector2(1, 1)
				
func unlock_form(form_name: String) -> void:
	if not unlocked_forms.has(form_name) and ALL_FORMS.has(form_name):
		unlocked_forms.append(form_name)
		print(form_name, "form unlocked!")

# Melee attack: deal damage to nearby enemy

func perform_melee_attack() -> void:
	# This is a placeholder implementation of a melee attack.
	# In an actual game, you might create a hitbox Area2D or check for enemies in range.
	print("Player performs a melee attack")
	# For example, we could have an Area2D node as a child for attack range and enable it here to detect enemies.

# Shoot a basic bullet (pistol)
func shoot_bullet() -> void:
	print("Pistol fired")
	if BulletScene:
		var bullet = BulletScene.instantiate()
		bullet.position = position + Vector2(facing_direction * 20, 0)
		if bullet.has_method("setup"):
			bullet.setup(facing_direction)
		elif bullet.has_variable("_velocity"):
			bullet._velocity = Vector2(facing_direction * 800, 0)
		get_parent().add_child(bullet)

func shoot_homing_rocket() -> void:
	print("Homing rocket launched")
	if RocketScene:
		var rocket = RocketScene.instantiate()
		rocket.position = position
		get_parent().add_child(rocket)
		# Assume the rocket's script will handle seeking a target on its own.
		# (We could pass a target reference if one is easily available, or rocket finds nearest enemy.)

# Fire a laser beam
func fire_laser_beam(delta: float) -> void:
	# For demonstration, we'll just print continuously.
	# A real implementation might cast a Ray2D forward and damage any hit object every frame.
	print("Firing laser beam...")

# Use grappling hook
func use_grappling_hook() -> void:
	print("Grappling hook fired")
	# Simple example: cast a ray in the facing direction to find a wall or object
	var max_distance = 500.0
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(position, position + Vector2(facing_direction * max_distance, -100))
	var result = space_state.intersect_ray(query)
	if result.size() > 0:
		# If hit something (wall or object), teleport player closer to that point as a simplistic effect
		var hit_position = result["position"]
		# Move player towards hit point (not exactly teleport all the way for balance)
		position = position.move_toward(hit_position, 300)
		print("Grappled to point ", hit_position)
	else:
		print("Grapple missed")

# Spawn a clone of the player
func spawn_clone() -> void:
	print("Spawning a clone")
	if CloneScene:
		var clone = CloneScene.instantiate()
		clone.position = position + Vector2(0, 10)  # spawn clone at player's position (slightly offset)
		get_parent().add_child(clone)
		# We assume CloneScene is a simpler character that maybe mimics player or stands in place.

# Teleport ability (could swap with object or blink to location)
func use_teleport() -> void:
	print("Teleport ability used")
	# Placeholder: teleport the player a short distance forward
	position.x += facing_direction * 100
	# In a real game, this could target a specific object or location. For example, if an enemy is targeted, swap positions with them.

