extends PlayerState
class_name PlayerFall

@export_group("Transitions")
@export var idle: State = null
@export var run: State = null
@export var jump: State = null
@export var adash: State = null
@export var ajump: State = null
@export var wall: State = null
@export var wjump: State = null

func state_enter() -> void:
	super()
	player.anim_sm.travel("fall")

func state_physics(delta: float) -> State:

	var direction:= player.get_direction()
	player.velocity.x = player.speed*direction
	player.apply_gravity(delta)

	player.was_on_floor = player.check_floor()
	player.apply_movement(direction)
	player.on_floor = player.check_floor()
	player.on_wall = player.check_wall()

	if player.on_wall and (player.stats.abilities & 0b100):
		if direction:
			if player.wall_normal != Vector2.ZERO and direction*player.wall_normal.x < 0 and player.wall_cooldown_timer.is_stopped():
				return wall

	if player.on_floor:
		if direction:
			return run
		return idle

	return null

func state_input(event: InputEvent) -> State:
	if event.is_action_pressed("jump"):
		if player.velocity.y > 0:
			player.jump_buffer_timer.start()

		if player.on_wall:
			if player.wall_cooldown_timer.is_stopped() and (player.stats.abilities & 0b100):
				return wjump
		else:
			if player.can_ajump and (player.stats.abilities & 0b010):
				return ajump

	if event.is_action_pressed("dash") and (player.stats.abilities & 0b001):
		if player.dash_cooldown_timer.is_stopped() and player.can_adash:
			return adash

	return null

func state_animated(anim_name: StringName) -> State:
	return null
