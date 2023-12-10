extends PlayerState
class_name PlayerADash

@export_group("Transitions")
@export var idle: State = null
@export var run: State = null
@export var fall: State = null
@export var ajump: State = null

func state_enter() -> void:
	super()
	player.velocity.x = player.dash_force*player.face_direction
	player.velocity.y = 0
	player.dash_timer.start()
	player.dash_ghost_tweener()
	player.can_adash = false
	player.anim_sm.travel("adash")

func state_exit() -> void:
	super()
	player.dash_cooldown_timer.start()
	player.ghost_tweener.kill()

func state_physics(delta: float) -> State:

	var direction:= player.get_direction()

	player.was_on_floor = player.check_floor()
	player.apply_movement(direction)
	player.on_floor = player.check_floor()
	player.on_wall = player.check_wall()

	if player.dash_timer.is_stopped():
		if player.on_floor:
			if direction:
				return run
			else:
				return idle
		else:
			if not player.dash_jump_buffer_timer.is_stopped():
				return ajump

			return fall

	return null

func state_input(event: InputEvent) -> State:
	if event.is_action_pressed("jump")  and (player.stats.abilities & 0b010):
		player.dash_jump_buffer_timer.start()
	return null

func state_animated(anim_name: StringName) -> State:
	return null
