extends PlayerState

@export_group("Transitions")
@export var idle: State = null
@export var run: State = null
@export var fall: State = null

func state_enter() -> void:
	super()
	if machine.partner.current_state == $"../../ActionStateMachine/Hurt":
		player.velocity.x = -player.face_direction*player.speed
		player.velocity.y = -0.5*player.jump_force

func state_physics(delta: float) -> State:
	if machine.partner.current_state == $"../../ActionStateMachine/Hurt":
		player.apply_movement(player.face_direction)

	return null

func state_exit() -> void:
	if machine.partner.current_state == $"../../ActionStateMachine/Hurt":
		player.velocity.x = 0

func state_animated(anim_name: StringName) -> State:
	if anim_name in ["hurt_left","hurt_right"]:
		if player.check_floor():
			if player.get_direction():
				return run
			else:
				return idle
		else:
			return fall

	return null
