extends CombatState
class_name SkillState

# Called when the node enters the scene tree for the first time.
func enter():
	#print("skill")
	var form = player.get_current_form_id()
	match form:
		"Magus":
			#player.anim_sprite.play("magus_attack")
			# You could also spawn a fireball or magic effect here
			print("Magus skill")
			player.still_animation = true
			player.anim_state.travel("ability_magus")
		"Cyber":
			#player.anim_sprite.play("cyber_slash")
			# Maybe activate grapple or combo effects
			print("Cyber skill")
			player.still_animation = true
			player.anim_state.travel("ability_cyber")
		"UltimateMagus":
			#player.anim_sprite.play("ultimate_magus_blast")
			# Big AoE logic here
			print("Ultimate Magus skill")
			player.still_animation = true
			player.anim_state.travel("ability_ult_magus")
		"UltimateCyber":
			#player.anim_sprite.play("ultimate_cyber_strike")
			# Laser or time freeze here
			print("Ultimate Cyber skill")
			player.still_animation = true
			player.anim_state.travel("ability_ult_cyber")
		"Normal":
			#player.anim_sprite.play("normal_attack")
			#print("Normal skill")
			pass
			#player.still_animation = true
# Called every frame. 'delta' is the elapsed time since the previous frame.
func physics_update(delta):
	if !(Input.is_action_just_pressed("no")) and player.still_animation == false:
		if player.is_on_floor():
			if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
				#print("IdleState: Detected movement input → switching to RunState")
				get_parent().change_state(RunState.new(player))
			else:
				#print("IdleState: Detected movement input → switching to IdleState")
				get_parent().change_state(IdleState.new(player))

		else:
			#print("IdleState: Detected movement input → switching to JumpState")
			get_parent().change_state(JumpState.new(player))
