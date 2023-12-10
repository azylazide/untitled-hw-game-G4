extends PlayerState
class_name PlayerAJump

@export_group("Transitions")
@export var fall: State = null
@export var adash: State = null

func state_enter() -> void:
	super()
	player.jump_reset()
	player.can_ajump = false

	player.velocity.y = -player.jump_force*player.platformer_settings.air_jump_multiplier
	player.anim_sm.travel("jump")


func state_physics(delta: float) -> State:

	var direction:= player.get_direction()
	player.velocity.x = player.speed*direction
	player.apply_gravity(delta)

	player.was_on_floor = player.check_floor()
	player.apply_movement(direction)
	player.on_floor = player.check_floor()
	player.on_wall = player.check_wall()

	if player.velocity.y > 0:
		return fall

	return null

func state_input(event: InputEvent) -> State:
	if event.is_action_pressed("dash") and (player.stats.abilities & 0b001):
		if player.dash_cooldown_timer.is_stopped() and player.can_adash:
			return adash

	if event.is_action_released("jump"):
		if player.velocity.y < -player.min_jump_force:
			player.velocity.y = -player.min_jump_force
			return fall
		else:
			return fall

	return null

func state_animated(anim_name: StringName) -> State:
	return null
