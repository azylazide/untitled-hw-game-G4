extends PlayerState

@export_group("Transitions")
@export var idle: State = null
@export var fall: State = null
@export var adash: State = null
@export var wjump: State = null

func state_enter() -> void:
	super()
	player.can_adash = true
	player.velocity.x = 0
	player.velocity.y = 0
	player.wall_cooldown_timer.start()
	player.wall_slide_timer.start()
	pass

func state_physics(delta: float) -> State:

	var direction:= player.get_direction()
	player.velocity.y += player.platformer_settings.wall_slide_multiplier*player.fall_gravity*delta
	player.velocity.y = minf(player.velocity.y,0.5*player.max_fall_tile*Globals.TILE_UNITS)

	player.was_on_floor = player.check_floor()
	player.apply_movement(direction)
	player.on_floor = player.check_floor()
	player.on_wall = player.check_wall()

	if player.wall_slide_timer.is_stopped():
		if direction*player.wall_normal.x > 0:
			return fall


	player.face_direction = signf(player.wall_normal.x)

	if player.on_floor:
		return idle

	if not player.on_wall:
		return fall

	return null

func state_input(event: InputEvent) -> State:
	if event.is_action_pressed("jump"):
		return wjump
	if event.is_action_pressed("dash") and (player.stats.abilities & 0b001):
		if player.dash_cooldown_timer.is_stopped():
			return adash

	return null

func state_animated(anim_name: StringName) -> State:
	return null
