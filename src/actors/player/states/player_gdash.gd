extends PlayerState
class_name PlayerGDash

@export_group("Transitions")
@export var idle: State = null
@export var run: State = null
@export var fall: State = null
@export var jump: State = null

func state_enter() -> void:
	super()
	player.velocity.x = player.dash_force*player.face_direction
	player.dash_timer.start()
	player.dash_ghost_tweener()
	player.anim_sm.travel("gdash")

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

	if not player.on_floor:
		if player.was_on_floor:
			player.coyote_timer.start()

	if player.dash_timer.is_stopped():
		if player.on_floor:
			if direction:
				return run
			else:
				return idle
		elif not player.on_floor and not player.was_on_floor:
			return fall

	return null

func state_input(event: InputEvent) -> State:
	if event.is_action_pressed("jump"):
		return jump
	return null

func state_animated(anim_name: StringName) -> State:
	return null
