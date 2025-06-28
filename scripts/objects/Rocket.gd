extends Area2D
class_name Rocket

@export var speed = 300.0        # How fast the rocket travels
@export var rotation_speed = 40.0 # How quickly the rocket turns towards its target
@export var damage = 40          # How much damage the rocket deals
@export var lifetime = 1.0       # How long the rocket exists before despawning (seconds)

var target: Node2D = null        # The enemy the rocket is trying to hit

func _ready():
	# Connect the body_entered signal to handle collisions with other physics bodies
	body_entered.connect(_on_body_entered)

	# Set up the lifetime timer
	$Timer.wait_time = lifetime
	$Timer.one_shot = true      # The timer will only run once
	$Timer.start()              # Start the timer
	$Timer.timeout.connect(_on_lifetime_timeout) # Connect the timeout signal

	# Rockets should be on a specific physics layer/mask to interact only with enemies
	# Ensure your Project Settings -> Layer Names are set up correctly for 'Enemies'

func _physics_process(delta):
	# Find the closest enemy if no target is currently set or if the current target is invalid
	if not is_instance_valid(target):
		target = find_closest_enemy()

	if target:
		# Calculate the direction from the rocket to the target
		var direction_to_target = (target.global_position - global_position).normalized()

		# Calculate the desired angle towards the target
		var target_angle = direction_to_target.angle()

		# Smoothly rotate the rocket towards the target angle
		# 'rotation' is the current angle of the rocket sprite
		rotation = lerp_angle(rotation, target_angle, delta * rotation_speed)

	# Move the rocket forward in its current rotated direction
	# 'transform.x' gives the forward vector of the node based on its rotation
	global_position += transform.x * speed * delta


func find_closest_enemy() -> Node2D:
	var closest_enemy: Node2D = null
	var min_distance_sq = INF # Use squared distance for faster comparison

	# Iterate through all nodes in the "Enemies" group
	# You need to make sure your enemies are added to this group!
	var enemies = get_tree().get_nodes_in_group("Enemies")

	for enemy in enemies:
		# Ensure the enemy is a valid instance (not deleted)
		if is_instance_valid(enemy):
			var distance_sq = global_position.distance_squared_to(enemy.global_position)
			if distance_sq < min_distance_sq:
				min_distance_sq = distance_sq
				closest_enemy = enemy
	return closest_enemy

func _on_body_entered(body: Node2D):
	# Check if the collided body has a "take_damage" method (e.g., an enemy)
	# This also acts as a simple "avoid platform" mechanism: if it hits a platform, it dies.
	if body.has_method("take_damage"):
		body.take_damage(damage)
		print("Rocket hit enemy and dealt ", damage, " damage.")
	elif body.is_in_group("Platforms"): # Assuming you have a "Platforms" group for obstacles
		print("Rocket hit a platform.")
		# Rockets explode on contact with platforms
	else:
		print("Rocket hit something else: ", body.name)

	# Destroy the rocket upon hitting anything to prevent multiple hits
	queue_free()

func _on_lifetime_timeout():
	# Destroy the rocket if its lifetime expires without hitting anything
	print("Rocket lifetime expired.")
	queue_free()
