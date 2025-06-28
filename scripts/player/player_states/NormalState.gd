extends BaseState
class_name NormalState

#var name: String = "Normal"

var combat_fsm: CombatFSM

const CombatFSM = preload("res://scripts/player/combat/CombatFSM.gd")
	
func _init(_player):
	player = _player
	combat_fsm = CombatFSM.new(player)
	add_child(combat_fsm)

func enter():
	Global.playerDamageAmount = 10
	print("Entered Normal State")
	# e.g. change player color or animation

func exit():
	pass

func physics_process(delta):
	combat_fsm.physics_update(delta)
	
	#print(player.health.current_hp)
	
	if player.canon_enabled == true or player.telekinesis_enabled == true:
		player.velocity = Vector2.ZERO
	else:

		player.scale = Vector2(0.75,0.75)
	

func handle_input(event):
	pass
