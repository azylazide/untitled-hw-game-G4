extends PlayerState

@export var neutral: State = null

func state_enter() -> void:
	super()

	if player.is_attack_charged:
		pass
	else:
		pass

	player.attack_finished = false
	player.attack_charge_timer.stop()
	player.player_attacked.emit(player.face_direction)

func state_physics(delta: float) -> State:

	if player.attack_finished:

		return neutral


	return null

func state_exit() -> void:
	#in case of interrupted attack
	player.attack_finished = true
	#match move state
	#	update anim
	pass

func state_animated(anim_name: StringName) -> State:
	#if anim name is attack
	#	player.attack_finished = true
	#	return neutral
	return null
