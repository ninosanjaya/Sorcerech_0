class_name Player
extends CharacterBody2D

# — Player constants and exported properties —
@export var move_speed = 300.0   # Walking speed in pixels/sec
@export var jump_force = 250.0   # Jump impulse force (vertical velocity for jump)
var gravity  = 1000.0     # Gravity strength (pixels/sec^2)


#@export var allow_grappling_hook: bool = false
@export var allow_camouflage: bool = false
#@export var allow_teleport: bool = false
@export var allow_time_freeze: bool = false
@export var telekinesis_enabled : bool = false
@export var current_magic_spot: MagusSpot = null
@export var canon_enabled : bool = false
@onready var telekinesis_controller = $TelekinesisController
@export var UI_telekinesis : bool = false

#@export var cannon_enabled: bool = false

var is_in_cannon = false
var is_aiming = false
var is_launched = false
var launch_direction = Vector2.ZERO
var launch_speed = 500.0 # adjust as needed
var aim_angle_deg = -90 # Default straight up

var facing_direction := 1 # 1 for right, -1 for left

var states = {}
var current_state: BaseState = null
var state_order = [ "UltimateMagus", "Magus","Normal", "Cyber", "UltimateCyber"]
var current_state_index = 2
var unlocked_states: Array[String] = ["Normal"]  # Start with only Normal state unlocked
# Maintain a separate dictionary to track unlocked status
var unlocked_flags = {
	"UltimateMagus": false,
	"Magus": false,
	"Normal": true,
	"Cyber": false,
	"UltimateCyber": false
}

var selected_form_index := 2  # This is for preview selection before confirming

var combat_fsm

@onready var anim_tree: AnimationTree = $AnimationTree
@onready var anim_state: AnimationNodeStateMachinePlayback = anim_tree.get("parameters/playback")
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var can_switch_form := true
var can_attack := true
var can_skill := true
var still_animation := false

@onready var form_cooldown_timer: Timer = $FormCooldownTimer
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var skill_cooldown_timer: Timer = $SkillCooldownTimer
@onready var sprite = $Sprite2D


@onready var AreaAttack = $AttackArea
@onready var AreaAttackColl = $AttackArea/CollisionShape2D
@export var health = 100
@export var health_max = 100
@export var health_min = 0

@onready var Hitbox = $Hitbox
var can_take_damage: bool
var dead: bool
var player_hit: bool = false

#var knockback_force = -20
var knockback_velocity := Vector2.ZERO
var knockback_duration := 0.2
var knockback_timer := 0.0

# Add to player.gd variables
var is_grappling := false
var grapple_joint := Vector2.ZERO
var grapple_length := 0.0

const FLOOR_NORMAL: Vector2 = Vector2(0, -1) # Standard for side-scrolling 2D

var wall_jump_just_happened = false
var wall_jump_timer := 0.0
const WALL_JUMP_DURATION := 0.3

@export var fireball_scene: PackedScene =  preload("res://scenes/objects/Fireball.tscn") # Will hold the preloaded Fireball.tscn
@onready var fireball_spawn_point = $FireballSpawnPoint

@export var rocket_scene: PackedScene = preload("res://scenes/objects/Rocket.tscn") # Will hold the preloaded Rocket.tscn


func _ready():
	# Preload and instantiate all states with reference to this Player
	#if gravity == null:
	#	gravity = 1000.0
		
	Global.playerBody = self
	Global.playerAlive = true
	
	dead = false
	can_take_damage = true
	
	AreaAttack.monitoring = false
	AreaAttackColl.disabled = true
	
	combat_fsm = CombatFSM.new(self)
	add_child(combat_fsm)
	
	anim_tree.active = true
	sprite.modulate = Color(1,1,1,1)
	
	#health.damaged.connect(_on_damaged)
	#health.died.connect(_on_died)
	
	states["Normal"] = NormalState.new(self)
	states["Magus"] = MagusState.new(self)
	states["Cyber"] = CyberState.new(self)
	states["UltimateMagus"] = UltimateMagusState.new(self)
	states["UltimateCyber"] = UltimateCyberState.new(self)
	
	
	switch_state("Normal")
	
	unlock_state("Magus")
	unlock_state("Cyber")
	unlock_state("UltimateMagus")
	unlock_state("UltimateCyber")
	
	# Set indices AFTER unlocking to valid values
	current_state_index = unlocked_states.find("Normal")
	if current_state_index == -1:
		current_state_index = 0
	selected_form_index = current_state_index
	
	#animation_player.animation_finished.connect(_on_animation_player_animation_finished)
	
	#form_cooldown_timer.timeout.connect(_on_form_cooldown_timer_timeout)
	#attack_cooldown_timer.timeout.connect(_on_attack_cooldown_timer_timeout)
	#skill_cooldown_timer.timeout.connect(_on_skill_cooldown_timer_timeout)

	#telekinesis_controller.setup(self)  # Pass player reference

	

func _physics_process(delta):
	#print(player_hit)
	if combat_fsm:
		combat_fsm.update_physics(delta)
	
	if current_state:
		current_state.physics_process(delta)
		
		
	Global.playerDamageZone = AreaAttack #deal_damage_zone
	Global.playerHitbox = Hitbox
	#rint(Global.playerDamageZone.monitoring)
	#print(current_state_index)
	
	if telekinesis_controller.is_ui_open == true:
		UI_telekinesis = true
	elif telekinesis_controller.is_ui_open == false:
		UI_telekinesis = false
		
	
	
	var input_dir = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	if Input.is_action_pressed("move_right") and not wall_jump_just_happened:
		facing_direction = 1
	elif Input.is_action_pressed("move_left") and not wall_jump_just_happened:
		facing_direction = -1
		
		
	if wall_jump_timer > 0:
		wall_jump_timer -= delta
		if wall_jump_timer <= 0:
			wall_jump_just_happened = false
	
		
	if not is_on_floor():
		velocity.y += gravity * delta
	
	#if is_grappling:
		# Reset vertical velocity to prevent falling
	#	velocity.y = 0
	#	return
		
	if !dead:
		
			
		if knockback_timer > 0:
			velocity = knockback_velocity
			knockback_timer -= delta
		elif canon_enabled == true :
			scale = Vector2(0.5,0.5)
			velocity = Vector2.ZERO
	
		elif telekinesis_enabled == true :
			velocity = Vector2.ZERO
			
			#if Input.is_action_just_pressed("no") and can_skill and current_state_index != 2:
			#	can_skill = false
			#	skill_cooldown_timer.start(5.0)
				
		else:
			if facing_direction == -1 and !dead:
				sprite.flip_h = true
			else:
				sprite.flip_h = false
				
			if not wall_jump_just_happened:
				velocity.x = input_dir * move_speed
			if is_on_floor() and Input.is_action_just_pressed("move_up"):  # Jump
				velocity.y = -jump_force
	
		if Input.is_action_just_pressed("yes") and can_attack and current_state_index != 2:
			can_attack = false
			attack_cooldown_timer.start(1.0)  # 0.5 sec cooldown
	#current_state.attack()  # or similar logic

		if Input.is_action_just_pressed("no") and can_skill and current_state_index != 2:
			can_skill = false
			skill_cooldown_timer.start(1.0)
		
		check_hitbox()
	elif dead:
		velocity = Vector2.ZERO
	
	#var applied_delta = delta # Start with the actual delta
	#if Global.time_freeze == true:
		 # If time is frozen, we use a fixed time step for player movement.
	# This makes the player ignore the global time_scale affecting 'delta'.
	#	applied_delta = 1.0 / Engine.physics_ticks_per_second # This uses Godot's physics update rate (e.g., 1/60th of a second)

		# Add other directional inputs (e.g., move_up/jump, move_down) as needed

	 # --- Your Player Movement Logic (adapt to your existing code) ---
	# --- Apply Gravity (always, but use applied_delta if time frozen) ---
	#	if not is_on_floor(): # CharacterBody2D has built-in is_on_floor()
	#		velocity.y += gravity * applied_delta # Directly modify the 'velocity' property

		# --- Handle Jump Input (only if on floor) ---
	#	if Input.is_action_just_pressed("move_up") and is_on_floor(): # Assuming "move_up" is your jump action
	#		velocity.y = jump_force

		# --- Handle Horizontal Input ---
	#	var input_direction = Input.get_vector("move_left", "move_right", "ui_up", "ui_down")
		# For horizontal movement:
	#	if input_direction.x != 0:
	#		velocity.x = input_direction.x * move_speed
	#	else:
	#		velocity.x = move_toward(velocity.x, 0, move_speed) # Smoothly stop if no horizontal input
	#	move_and_slide()



	move_and_slide()
	#print(unlocked_states[current_state_index])
	
	# --- FORM ROTATION ---
	if Input.is_action_just_pressed("form_next"):
		selected_form_index = (selected_form_index + 1) % unlocked_states.size()
		print("Selected form: ", unlocked_states[selected_form_index])

	if Input.is_action_just_pressed("form_prev"):
		selected_form_index = (selected_form_index - 1 + unlocked_states.size()) % unlocked_states.size()
		print("Selected form: ", unlocked_states[selected_form_index])

	if Input.is_action_just_pressed("form_apply") and !dead:
		if selected_form_index != current_state_index:
			current_state_index = selected_form_index
			switch_state(unlocked_states[current_state_index])  # ADD THIS LINE
			combat_fsm.change_state(IdleState.new(self))
			#print("Switched to form: ", unlocked_states[current_state_index])
			can_switch_form = false
			form_cooldown_timer.start(3)  # Cooldown time in seconds
	
	
		#current_state.use_skill()
	
	if is_aiming:
		print("enter canon3")
		if Input.is_action_pressed("move_left"):
			aim_angle_deg = clamp(aim_angle_deg - 1, -170, -10) # restrict angle
		elif Input.is_action_pressed("move_right"):
			aim_angle_deg = clamp(aim_angle_deg + 1, -170, -10)
		update_aim_ui(aim_angle_deg)
	launch_direction = Vector2.RIGHT.rotated(deg_to_rad(aim_angle_deg))
	
	if is_in_cannon and is_aiming and Input.is_action_just_pressed("yes"):
		print("FIRE!")
		launch_direction = Vector2.RIGHT.rotated(deg_to_rad(aim_angle_deg))
		is_aiming = false
		is_launched = true
		is_in_cannon = false
		show_aim_ui(false)
		
		#sprite.play("flying") # change to appropriate flying sprite
	if is_launched:
		velocity = launch_direction * launch_speed
		move_and_slide()
		print("HIT?")
		# Optional stop condition:
		if is_on_floor() or is_on_ceiling() or is_on_wall():
			is_launched = false
			velocity = Vector2.ZERO
			#sprite.play("idle") # revert sprite to default
			print("HIT!")
			canon_enabled = false
	

		
func get_current_form_id() -> String:
	if current_state_index >= 0 and current_state_index < unlocked_states.size():
		return unlocked_states[current_state_index]
	else:
		return "Normal"  # fallback to prevent crash

func _input(event):
	if current_state:
		current_state.handle_input(event)
		
		# Example: switch to next unlocked state with Q
		

func switch_state(state_name: String) -> void:
	if current_state:
		current_state.exit()
	current_state = states[state_name]
	current_state.enter()

	#current_state_index = state_order.find(state_name)



# --- Unlocking system ---

func unlock_state(state_name: String) -> void:
	if unlocked_flags.has(state_name):
		unlocked_flags[state_name] = true
		# Rebuild unlocked_states in state_order sequence
		unlocked_states = []
		for state in state_order:
			if unlocked_flags[state]:
				unlocked_states.append(state)

		# Update indices to stay on current state
		#current_state_index = unlocked_states.find(current_state.name)
		#selected_form_index = current_state_index
		
func lock_state(state_name: String) -> void:
	if unlocked_states.has(state_name) and state_name != "Normal":
		unlocked_states.erase(state_name)
		print("Locked state:", state_name)
		

func enter_cannon():
	is_in_cannon = true
	is_aiming = true
	velocity = Vector2.ZERO
	show_aim_ui(true)
	print("enter canon2")
	# Optionally disable animations or switch to a "cannon idle" sprite
	
func show_aim_ui(visible: bool):
	$AimUI.visible = visible

func update_aim_ui(angle):
	$AimUI.rotation_degrees = angle
	
func get_nearby_telekinesis_objects() -> Array[TelekinesisObject]:
	var results: Array[TelekinesisObject] = []
	var radius = 200

	var all = get_tree().get_nodes_in_group("TelekinesisObject")
	print("Found in group:", all.size())

	for obj in all:
		print("Checking:", obj.name)
		var dist = obj.global_position.distance_to(global_position)
		print("Distance to player:", dist)
		if dist < radius:
			results.append(obj)

	print("Final results:", results)
	return results
	

		



func _on_form_cooldown_timer_timeout():
	can_switch_form = true


func _on_attack_cooldown_timer_timeout():
	can_attack = true
	AreaAttack.monitoring = false
	AreaAttackColl.disabled = true

func _on_skill_cooldown_timer_timeout():
	can_skill = true


func _on_animation_tree_animation_finished(anim_name):
	still_animation = false
	print("animation end")



func check_hitbox():
	var hitbox_areas = $Hitbox.get_overlapping_areas()
	var damage: int
	if hitbox_areas:
		var hitbox = hitbox_areas.front()
		if hitbox.get_parent() is EnemyA:
			damage = Global.enemyADamageAmount
		
	if can_take_damage:
		if Global.enemyAdealing == true:
			#print("TAKING DAMAGEEEEE")
			#var knockback_dir = position.direction_to(player.global_position) * knockback_force
			
			#velocity.x = knockback_dir.x	
			take_damage(damage)
			
			
func take_damage(damage):
	#print(damage)
	if damage != 0:
		apply_knockback(Global.enemyAknockback)
		#player_hit = true
		#print("change")
		player_hit = true
		if health > 0:
			#call_deferred("_reset_hit_flag")  # Schedule reset for end of frame
			health -= damage
			print("player heath", health)
			if health <= 0:
				health = 0
				dead = true
				Global.playerAlive = false
				print("PLAYER DEAD")
			take_damage_cooldown(1.0)
		await get_tree().create_timer(0.5).timeout
		player_hit = false
			
		# Play death animation or transition
# Reset the flag at the end of the frame
#func _reset_hit_flag():
#	player_hit = false
	
func take_damage_cooldown(time):
	#player_hit = false
	print("cooldown")
	can_take_damage = false
	await get_tree().create_timer(time).timeout
	can_take_damage = true
	#player_hit = false
	
func apply_knockback(vector: Vector2):
	knockback_velocity = vector
	knockback_timer = knockback_duration
	
func shoot_fireball():
	if not fireball_scene:
		print("ERROR: Fireball scene not assigned in Player.gd's Inspector!")
		return

	var fireball_instance = fireball_scene.instantiate()
	# Add the fireball to the main scene tree so it moves independently
	get_tree().current_scene.add_child(fireball_instance)

	# Determine the fireball's direction based on the player's facing direction
	var fb_direction = Vector2(facing_direction, 0) # facing_direction is 1 for right, -1 for left

	# Calculate the spawn position based on the player's global position and facing direction.
	# fireball_spawn_point.position is the LOCAL offset relative to the player's origin.
	# We multiply its X-component by facing_direction to mirror it horizontally.
	var spawn_offset_x = fireball_spawn_point.position.x * facing_direction
	var spawn_offset_y = fireball_spawn_point.position.y # Y-offset typically doesn't need mirroring

	# Combine the player's global position with this calculated offset
	fireball_instance.global_position = global_position + Vector2(spawn_offset_x, spawn_offset_y)

	# Set the fireball's movement direction
	fireball_instance.set_direction(fb_direction)

	# Optional: Trigger a shooting animation for the player
	# if anim_state:
	#     anim_state.travel("Magus_Attack") # Assuming you have a Magus attack animation
	print("Player in Magus mode shot a fireball!")

	# player.gd - Add this function
func shoot_rocket():
	if not rocket_scene:
		print("ERROR: Rocket scene not assigned in Player.gd's Inspector!")
		return

	var rocket_instance = rocket_scene.instantiate()
	# Add the rocket to the main scene tree, not as a child of the player.
	get_tree().current_scene.add_child(rocket_instance)

	# Position the rocket at the player's designated spawn point (reusing FireballSpawnPoint for simplicity)
	# Apply the same logic for flipping the spawn point based on facing_direction
	var spawn_offset_x = fireball_spawn_point.position.x * facing_direction
	var spawn_offset_y = fireball_spawn_point.position.y
	rocket_instance.global_position = global_position + Vector2(spawn_offset_x, spawn_offset_y)

	# The rocket's initial direction doesn't strictly matter for homing,
	# but it can be set for visual consistency or if it has an initial non-homing phase.
	# For a truly immediate homing, the rocket will find its target in its _physics_process.
	# However, it's good practice to give it an initial direction related to player facing.
	rocket_instance.rotation = Vector2(facing_direction, 0).angle()

	# Optional: Trigger a shooting animation for the player
	# if anim_state:
	#     anim_state.travel("UltimateCyber_Attack") # Assuming you have a Ultimate Cyber attack animation
	print("Player in Ultimate Cyber mode shot a homing rocket!")
		
