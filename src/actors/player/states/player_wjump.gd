extends PlayerState

@export_group("Transitions")
@export var fall: State = null
@export var adash: State = null

func state_enter() -> void:
	super()
	player.jump_reset()


	player.wall_jump_hold_timer.start()
	player.face_direction = signf(player.wall_normal.x)
	player.velocity.x = player.wall_kick_force*player.face_direction
	player.velocity.y = -player.jump_force


func state_physics(delta: float) -> State:

	var direction:= player.get_direction()
	player.apply_gravity(delta)

	player.was_on_floor = player.check_floor()
	player.apply_movement(direction)
	player.on_floor = player.check_floor()
	player.on_wall = player.check_wall()

	if player.velocity.y > 0:
		return fall

	return null

func state_input(event: InputEvent) -> State:
	if event.is_action_pressed("dash"):
		if player.dash_cooldown_timer.is_stopped():
			return adash

	return null

func state_animated(anim_name: StringName) -> State:
	return null
