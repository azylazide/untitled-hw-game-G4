extends ActorBase

var frame_count = 0

@export_group("Initial Values")
## Change the initial facing direction
@export_enum("LEFT","RIGHT") var initial_direction:= 1
## Initial movement state on ready
@export var initial_movement_state: MovementStates.STATES = MovementStates.STATES.IDLE
@export var initial_action_state: ActionStates.STATES = ActionStates.STATES.NEUTRAL

@export_group("Platformer Values")
@export_subgroup("Jump")
## Coyote time to temporarily float in seconds
@export var coyote_time:= 0.1
## Time jump inputs are remembered just before landing from falling in seconds
@export var jump_buffer_time:= 0.1
## Multiplier for air jump speed
@export var air_jump_multiplier:= 0.8
## Multiplier for ground dash jump speed
@export var dash_jump_multiplier:= 1.2

@export_subgroup("Dash")
## Dash duration in seconds
@export var dash_time:= 0.2
## Jump buffer time for jumping just before air dash stops
@export var dash_jump_buffer_time:= 0.2
## Duration until player can dash again
@export var dash_cooldown_time:= 0.2
## Distance travelled by dash
@export var dash_length:= 2.0

@export_subgroup("Wall")
## Duration of full wall kick air time
@export var wall_kick_time:= 0.5
## Velocity applied horizontally in wall kick
@export var wall_kick_power:= 2.5
## Cooldown time until another wall kick is allowed
@export var wall_cooldown_time:= 0.2
## Multiplier for gravity in wall sliding
@export var wall_slide_multiplier:= 0.1

## Ground shapecast
@onready var ground_cast:= $GroundDetector as ShapeCast2D

## Left wall shapecast
@onready var left_wall_detector:= $WallDetectors/Left as ShapeCast2D

## Right wall shapecast
@onready var right_wall_detector:= $WallDetectors/Right as ShapeCast2D

## Camera detector area
@onready var camera_bbox_detector := $CameraBBoxDetector as CameraBBoxDetector

## Camera center marker
@onready var camera_center := $CameraCenter as Marker2D

## Coyote duration timer
@onready var coyote_timer:= $Timers/CoyoteTimer as Timer

## Jump buffer timer
@onready var jump_buffer_timer:= $Timers/JumpBufferTimer as Timer

## Dash duration timer
@onready var dash_timer:= $Timers/DashTimer as Timer

## Dash duration timer
@onready var dash_jump_buffer_timer:= $Timers/DashJumpBufferTimer as Timer

## Dash cooldown duration timer
@onready var dash_cooldown_timer:= $Timers/DashCooldownTimer as Timer

## Wall slide duration timer
@onready var wall_slide_timer:= $Timers/WallSlideTimer as Timer

## Wall stick cooldown timer
@onready var wall_cooldown_timer:= $Timers/WallCooldownTimer as Timer

## Wall jump duration timer
@onready var wall_jump_hold_timer:= $Timers/WallJumpHoldTimer as Timer

## Hurt duration timer
@onready var hurt_timer:= $Timers/HurtTimer as Timer

## If on floor on previous frame
@onready var was_on_floor:= true

## Air dash is allowed
@onready var can_adash:= true

## Double jump is allowed
@onready var can_ajump:= true

## Wall normal for wall jumps and face directions
@onready var wall_normal:= Vector2.ZERO

## AnimationTree
@onready var anim_tree:= $AnimationTree

## AnimationPlayer
@onready var anim_player:= $AnimationPlayer


## Gravity applied to the player when in jump state
var jump_gravity: float
## Jump speed applied for interrupted jumping
var min_jump_force: float
## Gravity apllied to the player when falling
var fall_gravity: float
## Max fall speed
var max_fall_speed: float
## Horizontal speed applied to dash states
var dash_force: float
## Horizontal speed applied to wall jumps
var wall_kick_force: float


## If on floor on current frame
var on_floor: bool
## If on wall on current frame
var on_wall: bool

## MovementStates object that stores states information
var Move: MovementStates
var move_states_ref: Dictionary
var Action: ActionStates
var action_states_ref: Dictionary

var anim_sm: AnimationNodeStateMachinePlayback

## bool state changed by signal
var attack_finished:= true

## Stores movement states information
class MovementStates:
	extends StateContainer
	## Declare movement states
	enum STATES {IDLE,RUN,FALL,JUMP,GDASH,ADASH,WALL}
	
	func _init(current_state) -> void:
		super._init(current_state)
		_name_dict(STATES)

## Stores action states information
class ActionStates:
	extends StateContainer
	## Declare action states
	enum STATES {NEUTRAL,ATTACK,HURT,DEATH}
	
	func _init(current_state) -> void:
		super._init(current_state)
		_name_dict(STATES)

## Setup movement values
func _setup_movement() -> void:
	jump_gravity = Globals._gravity(jump_height,max_run_tile,gap_length)
	fall_gravity = Globals._gravity(1.5*jump_height,max_run_tile,0.8*gap_length)
	
	jump_force = Globals._jump_vel(max_run_tile,jump_height,gap_length)
	min_jump_force = Globals._jump_vel(max_run_tile,min_jump_height,gap_length/2.0)
	max_fall_speed = max_fall_tile*Globals.TILE_UNITS
	
	speed = max_run_tile*Globals.TILE_UNITS
	
	dash_force = Globals._dash_speed(dash_length,dash_time)
	
	wall_kick_force = Globals._wall_kick(wall_kick_power,wall_kick_time)
	
	face_direction = 1

## Setup timer durations
func _setup_timers() -> void:
	coyote_timer.wait_time = coyote_time
	jump_buffer_timer.wait_time = jump_buffer_time
	dash_timer.wait_time = dash_time
	dash_jump_buffer_timer.wait_time = dash_jump_buffer_time
	dash_cooldown_timer.wait_time = dash_cooldown_time
	wall_slide_timer.wait_time = 0.1
	wall_cooldown_timer.wait_time = wall_cooldown_time
	wall_jump_hold_timer.wait_time = 0.5
	pass

func _setup_anim() -> void:
	anim_sm = anim_tree.get("parameters/playback")
	anim_tree.active = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#create movementstates object
	Move = MovementStates.new(initial_movement_state)
	move_states_ref = Move.STATES
	Action = ActionStates.new(initial_action_state)
	action_states_ref = Action.STATES
	
	_setup_movement()
	_setup_timers()
	_setup_anim()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
#	print("physics started %d" %frame_count)
	#MOVEMENT STATEMACHINE
	_movement_statemachine(delta)
	_action_statemachine(delta)
	_resolve_animations()
	SignalBus.player_updated.emit(face_direction,camera_center.global_position,velocity,Move.current,Action.current)
#	print(is_on_wall())
	debug_text()
#	print("physics ended %d" %frame_count)
	frame_count += 1

## Movement state machine
## [br]-Checks if entering a new state
## [br]-Runs the set state and saves the next state to run
## [br]-Exit the state if different from current
## [br]-Handle the state swap
func _movement_statemachine(delta: float) -> void:
	#Coming from a different state in previous frame
	if Move.previous_frame != Move.current:
		_enter_movement_state(delta)
	#Run the state depending if initial or not
	Move.next = (_initial_movement_state(delta) if Move.previous_frame == Move.NULL 
							else _run_movement_state(delta))
	#If transitioning, run exit code
	if Move.next != Move.current:
		_exit_movement_state(delta,Move.current)
	#transition
	#change_movement_state(Move.next)
	Move.change_state()
	pass

func _action_statemachine(delta: float) -> void:
	#Coming from a different state in previous frame
	if Action.previous_frame != Action.current:
		_enter_action_state(delta)
	#Run the state depending if initial or not
	Action.next = (_initial_action_state(delta) if Action.previous_frame == Action.NULL 
							else _run_action_state(delta))
	#If transitioning, run exit code
	if Action.next != Action.current:
		_exit_action_state(delta,Action.current)
	#transition
	Action.change_state()

## Initial states that run first
func _initial_movement_state(delta: float) -> int:
	return Move.STATES.IDLE

func _initial_action_state(delta: float) -> int:
	match Action.current:
		Action.STATES.NEUTRAL:
			return Action.STATES.NEUTRAL
		Action.STATES.DEATH:
			return Action.STATES.DEATH
	
	return Action.STATES.NEUTRAL

## States setup when transitioning into
func _enter_movement_state(delta: float) -> void:
	match Move.current:
		Move.STATES.IDLE:
			_ground_reset()
			return
		Move.STATES.RUN:
			_ground_reset()
			return
		Move.STATES.JUMP:
			coyote_timer.stop()
			jump_buffer_timer.stop()
			_enter_jump()
			return
		Move.STATES.GDASH:
			dash_cooldown_timer.start()
			velocity.x = dash_force*face_direction
			dash_timer.start()
			return
		Move.STATES.ADASH:
			dash_cooldown_timer.start()
			can_adash = false
			velocity.x = dash_force*face_direction
			velocity.y = 0
			dash_timer.start()
			return
		Move.STATES.WALL:
			can_adash = true
			velocity.x = 0
			velocity.y = 0
			wall_cooldown_timer.start()
			wall_slide_timer.start()
	pass

func _enter_action_state(delta: float) -> void:
	pass

## Main states code that runs per frame
func _run_movement_state(delta: float) -> int:
	
	if Action.current in [Action.STATES.DEATH,Action.STATES.HURT]:
		match Action.STATES:
			Action.STATES.HURT:
				#ignore player input
				#apply knockback while hurt time is active
				#return AUTO
				#when done change AUTO to IDLE or RUN or FALL
				pass
			Action.STATES.DEATH:
				#ignore player input
				#apply simple physics for gravity or knockback
				#always stay as AUTO
				pass
		return Move.AUTO
	
	else:
		match Move.current:
			Move.STATES.IDLE:
				var dir:= get_direction()
				velocity.x = 0
				#_apply_gravity(delta)
				
				was_on_floor = check_floor()
				_apply_movement(dir)
				on_floor = check_floor()
				on_wall = check_wall()
				
				if dir != 0:
					anim_sm.travel("run")
					return Move.STATES.RUN
				
				if not on_floor:
					if was_on_floor:
						coyote_timer.start()
					else:
						anim_sm.travel("fall")
						return Move.STATES.FALL
				
				if not jump_buffer_timer.is_stopped() and on_floor:
					jump_buffer_timer.stop()
					anim_sm.travel("jump")
					return Move.STATES.JUMP
				
				anim_tree.set("parameters/idle/blend_position",face_direction)
				return Move.STATES.IDLE
				
			Move.STATES.RUN:
				var dir:= get_direction()
				velocity.x = speed*dir
				#_apply_gravity(delta)
				
				was_on_floor = check_floor()
				_apply_movement(dir)
				on_floor = check_floor()
				on_wall = check_wall()
				
				if dir == 0 and on_floor:
					anim_sm.travel("idle")
					return Move.STATES.IDLE
				
				if not on_floor:
					if was_on_floor:
						coyote_timer.start()
					else:
						anim_sm.travel("fall")
						return Move.STATES.FALL
				
				if not jump_buffer_timer.is_stopped() and on_floor:
					jump_buffer_timer.stop()
					anim_sm.travel("jump")
					return Move.STATES.JUMP
					
				anim_tree.set("parameters/run/blend_position",face_direction)
				return Move.STATES.RUN
			
			Move.STATES.FALL:
				var dir:= get_direction()
				velocity.x = speed*dir
				_apply_gravity(delta)
				
				was_on_floor = check_floor()
				_apply_movement(dir)
				on_floor = check_floor()
				on_wall = check_wall()
				
				if on_wall and (stats.abilities & 0b100):
					if dir != 0:
						if wall_normal != Vector2.ZERO and dir*wall_normal.x < 0 and wall_cooldown_timer.is_stopped():
							anim_sm.travel("wall")
							return Move.STATES.WALL
						elif wall_normal.x == 0:
							#edge case review later; use face direction
							pass
				
				if on_floor:
					anim_tree.set("parameters/land/blend_position",face_direction)
					anim_sm.travel("idle")
					return Move.STATES.IDLE
				
				anim_tree.set("parameters/fall/blend_position",face_direction)
				return Move.STATES.FALL
			
			Move.STATES.JUMP:
				_apply_gravity(delta)
				var dir:= get_direction()
				if wall_jump_hold_timer.is_stopped():
					velocity.x = speed*dir
				
				was_on_floor = check_floor()
				_apply_movement(dir)
				on_floor = check_floor()
				on_wall = check_wall()
							
				if velocity.y > 0:
					anim_sm.travel("fall")
					return Move.STATES.FALL
				
				anim_tree.set("parameters/jump/blend_position",face_direction)
				return Move.STATES.JUMP
			
			Move.STATES.GDASH:
				var dir:= get_direction()
				
				was_on_floor = check_floor()
				_apply_movement(dir)
				on_floor = check_floor()
				on_wall = check_wall()
				
				if not on_floor:
					if was_on_floor:
						coyote_timer.start()
				
				if dash_timer.is_stopped():
					if on_floor:
						if dir != 0:
							anim_sm.travel("run")
							return Move.STATES.RUN
						else:
							anim_sm.travel("idle")
							return Move.STATES.IDLE
					elif not on_floor and not was_on_floor:
						anim_sm.travel("fall")
						return Move.STATES.FALL
				
				anim_tree.set("parameters/gdash/blend_position",face_direction)
				return Move.STATES.GDASH
			
			Move.STATES.ADASH:
				var dir:= get_direction()
				
				was_on_floor = check_floor()
				_apply_movement(dir)
				on_floor = check_floor()
				on_wall = check_wall()
				
				if dash_timer.is_stopped():
					if on_floor:
						if dir != 0:
							anim_sm.travel("run")
							return Move.STATES.RUN
						else:
							anim_sm.travel("idle")
							return Move.STATES.IDLE
					else:
						if not dash_jump_buffer_timer.is_stopped():
							can_ajump = false
							anim_sm.travel("jump")
							return Move.STATES.JUMP
						else:
							anim_sm.travel("fall")
							return Move.STATES.FALL
				
				anim_tree.set("parameters/adash/blend_position",face_direction)
				return Move.STATES.ADASH
				
			Move.STATES.WALL:
				#snap?
				var dir:= get_direction()
				velocity.y += wall_slide_multiplier*fall_gravity*delta
				velocity.y = min(velocity.y,0.5*max_fall_tile*Globals.TILE_UNITS) 
				
				was_on_floor = check_floor()
				_apply_movement(dir)
				on_floor = check_floor()
				on_wall = check_wall()
				
				if wall_slide_timer.is_stopped():
						if dir*wall_normal.x > 0:
							anim_sm.travel("fall")
							return Move.STATES.FALL
				
				if on_floor:
					face_direction = signf(wall_normal.x)
					anim_sm.travel("idle")
					return Move.STATES.IDLE
				
				if not on_wall:
					face_direction = signf(wall_normal.x)
					anim_sm.travel("fall")
					return Move.STATES.FALL
				
				face_direction = signf(wall_normal.x)
				anim_tree.set("parameters/wall/blend_position",face_direction)
				return Move.STATES.WALL

	#-------------
	return Move.NULL

func _run_action_state(delta: float) -> int:
	match Action.current:
		Action.STATES.NEUTRAL:
			return Action.STATES.NEUTRAL
		Action.STATES.ATTACK:
#			print("attack")
#			if $Timers/testtimer.is_stopped():
#				attack_finished = true
#				return Action.STATES.NEUTRAL
#			if attack_finished:
#				match Move.current:
#					Move.STATES.IDLE:
#						anim_sm.travel("idle")
#						anim_tree.set("parameters/idle/blend_position",face_direction)
#					Move.STATES.RUN:
#						anim_sm.travel("run")
#						anim_tree.set("parameters/run/blend_position",face_direction)
#					_: #TEMP
#						anim_sm.travel("idle")
#						anim_tree.set("parameters/idle/blend_position",face_direction)
#				return Action.STATES.NEUTRAL
			if attack_finished or not (anim_sm.get_current_node() == "attack" or anim_sm.get_current_node() == "attack_air"):
				attack_finished = true
				return Action.STATES.NEUTRAL
			if anim_sm.get_current_node() == "attack":
				anim_tree.set("parameters/attack/blend_position",face_direction)
			else:
				anim_tree.set("parameters/attack_air/blend_position",face_direction)
			return Action.STATES.ATTACK
		Action.STATES.HURT:
			#invincibility timer
			return Action.STATES.NEUTRAL
		Action.STATES.DEATH:
			return Action.STATES.DEATH
					
	return Action.NULL

## Clean up when transitioning out to
func _exit_movement_state(delta: float, current: int) -> int:
	return 0

func _exit_action_state(delta: float, current: int) -> int:
	return 0

## Setup jump based on previous state for the jump enter setup
func _enter_jump() -> void:
	match Move.previous:
		Move.STATES.FALL:
			#against the wall
			if on_wall:
				#wall kick
				if wall_normal != Vector2.ZERO and wall_cooldown_timer.is_stopped()   and (stats.abilities & 0b100):
					wall_jump_hold_timer.start()
					face_direction = signf(wall_normal.x)
					velocity.x = wall_kick_force*face_direction
					velocity.y = -jump_force
				#if both walls use face direction as the focused wall
				
				#if no wall jump ability but must ajump
				elif can_ajump:
					can_ajump = false
					velocity.y = -jump_force*air_jump_multiplier
			#regular air jump
			else:
				velocity.y = -jump_force*air_jump_multiplier
		Move.STATES.GDASH:
			velocity.y = -jump_force*dash_jump_multiplier
		Move.STATES.ADASH:
			velocity.y = -jump_force*air_jump_multiplier
		Move.STATES.WALL:
			wall_jump_hold_timer.start()
			face_direction = signf(wall_normal.x)
			velocity.x = wall_kick_force*face_direction
			velocity.y = -jump_force
			
		#regular jump
		_:
			velocity.y = -jump_force

## Reset values upon touching ground
func _ground_reset() -> void:
	can_adash = true
	can_ajump = true

func get_direction() -> float:
	return Input.get_axis("left","right")

## Apply gravity based on falling, jumping and terminal situations
func _apply_gravity(delta: float) -> void:
	if velocity.y > 0:
		velocity.y += fall_gravity*delta
		
	else:
		velocity.y += jump_gravity*delta
	
	velocity.y = minf(velocity.y,max_fall_speed)

## Apply movement and save the current direction
func _apply_movement(dir: float) -> void:
	move_and_slide()
	if dir == 0:
		return
	else:
		face_direction = -1 if dir < 0 else 1

## Check floor with coyote
func check_floor() -> bool:
	#printt(is_on_floor(),is_on_floor_only(),on_floor)
	return is_on_floor() or not coyote_timer.is_stopped()

## Check walls using the shapecasts
func check_wall() -> bool:
	var left: bool = left_wall_detector.is_colliding()
	var right: bool = right_wall_detector.is_colliding()
	
	if left and right:
		wall_normal = Vector2.ZERO
		return true
	elif left:
		wall_normal = left_wall_detector.get_collision_normal(0)
		return true
	elif right:
		wall_normal = right_wall_detector.get_collision_normal(0)
		return true
	else:
		return false
	
func _unhandled_input(event: InputEvent) -> void:
	# attack states ignores this states (TEMP)
	if Action.current == Action.STATES.NEUTRAL:
		match Move.current:
			Move.STATES.IDLE:
				#regular jump
				if event.is_action_pressed("jump"):
					if on_floor:
						Move.next = Move.STATES.JUMP
						anim_sm.travel("jump")
						Move.change_state()
				
				#dash
				if event.is_action_pressed("dash") and (stats.abilities & 0b001):
					if dash_cooldown_timer.is_stopped():
						Move.next = Move.STATES.GDASH
						anim_sm.travel("gdash")
						Move.change_state()
		
			Move.STATES.RUN:
				#regular jump
				if event.is_action_pressed("jump"):
					if on_floor:
						Move.next = Move.STATES.JUMP
						anim_sm.travel("jump")
						Move.change_state()
				
				#dash
				if event.is_action_pressed("dash") and (stats.abilities & 0b001):
					if dash_cooldown_timer.is_stopped():
						Move.next = Move.STATES.GDASH
						anim_sm.travel("gdash")
						Move.change_state()
		
			Move.STATES.JUMP:
				#jump interrupt
				if event.is_action_released("jump"):
					#minimal jump
					if velocity.y < -min_jump_force:
						velocity.y = -min_jump_force
						Move.next = Move.STATES.FALL
						anim_sm.travel("fall")
						Move.change_state()
					
					#interrupt
					else:
						Move.next = Move.STATES.FALL
						anim_sm.travel("fall")
						Move.change_state()
				
				#air dash
				if event.is_action_pressed("dash") and (stats.abilities & 0b001):
					if dash_cooldown_timer.is_stopped() and can_adash:
						Move.next = Move.STATES.ADASH
						anim_sm.travel("adash")
						Move.change_state()
		
			Move.STATES.FALL:
				if event.is_action_pressed("jump"):
					#buffer jump
					if velocity.y > 0:
						jump_buffer_timer.start()
					#either wall jump or air jump depending on ability
					if on_wall:
						Move.next = Move.STATES.JUMP
						anim_sm.travel("jump")
						Move.change_state()
					#air jump
					elif not on_wall and can_ajump and (stats.abilities & 0b010):
						can_ajump = false
						jump_buffer_timer.stop()
						Move.next = Move.STATES.JUMP
						anim_sm.travel("jump")
						Move.change_state()
				#air dash
				if event.is_action_pressed("dash") and (stats.abilities & 0b001):
					if dash_cooldown_timer.is_stopped() and can_adash:
						Move.next = Move.STATES.ADASH
						anim_sm.travel("adash")
						Move.change_state()
		
			Move.STATES.GDASH:
				#dashed jump
				if event.is_action_pressed("jump"):
					if on_floor:
						Move.next = Move.STATES.JUMP
						anim_sm.travel("jump")
						Move.change_state()
				#dash
				if event.is_action_pressed("dash"):
					if dash_cooldown_timer.is_stopped():
						Move.next = Move.STATES.GDASH
						anim_sm.travel("gdash")
						Move.change_state()
		
			Move.STATES.ADASH:
				#air dash
				if event.is_action_pressed("jump")  and (stats.abilities & 0b010):
					dash_jump_buffer_timer.start()
			Move.STATES.WALL:
				#wall jump
				if event.is_action_pressed("jump"):
					Move.next = Move.STATES.JUMP
					anim_sm.travel("jump")
					Move.change_state()
				#wall dash in air
				if event.is_action_pressed("dash") and (stats.abilities & 0b001):
					face_direction = signf(wall_normal.x)
					Move.next = Move.STATES.ADASH
					anim_sm.travel("adash")
					Move.change_state()
	
	match Action.current:
		Action.STATES.NEUTRAL:
			if event.is_action_pressed("attack"):
#				print("ATTACK %d" %frame_count)
				if Move.current in [Move.STATES.IDLE,Move.STATES.RUN]:
					anim_sm.travel("attack")
					anim_tree.set("parameters/attack/blend_position",face_direction)
				elif Move.current in [Move.STATES.JUMP,Move.STATES.FALL,Move.STATES.WALL]:
					anim_sm.travel("attack_air")
					anim_tree.set("parameters/attack_air/blend_position",face_direction)
				else:
					return

				$Timers/testtimer.start()
				Action.next = Action.STATES.ATTACK
				attack_finished = false
				Action.change_state()

func _resolve_animations() -> void:
	match Action.current:
		Action.STATES.NEUTRAL:
			match Move.current:
				Move.STATES.IDLE:
					pass
				Move.STATES.RUN:
					pass
				Move.STATES.FALL:
					pass
				Move.STATES.JUMP:
					pass
				Move.STATES.GDASH:
					pass
				Move.STATES.ADASH:
					pass
				Move.STATES.WALL:
					pass
			pass
		Action.STATES.ATTACK:
			match Move.current:
				Move.STATES.IDLE:
					pass
				Move.STATES.RUN:
					pass
				Move.STATES.FALL:
					pass
				Move.STATES.JUMP:
					pass
				Move.STATES.GDASH:
					pass
				Move.STATES.ADASH:
					pass
				Move.STATES.WALL:
					pass
		Action.STATES.DEATH:
			match Move.current:
				Move.STATES.IDLE:
					pass
				Move.STATES.RUN:
					pass
				Move.STATES.FALL:
					pass
				Move.STATES.JUMP:
					pass
				Move.STATES.GDASH:
					pass
				Move.STATES.ADASH:
					pass
				Move.STATES.WALL:
					pass
	pass

func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
#	print(anim_name)
	if anim_name in ["attack_right","attack_left","attack_air_right","attack_air_left"]:
		attack_finished = true
		match Move.current:
			Move.STATES.IDLE:
				anim_sm.travel("idle")
				anim_tree.set("parameters/idle/blend_position",face_direction)
			Move.STATES.RUN:
				anim_sm.travel("run")
				anim_tree.set("parameters/run/blend_position",face_direction)
			Move.STATES.FALL:
				anim_sm.travel("fall")
				anim_tree.set("parameters/fall/blend_position",face_direction)
			Move.STATES.WALL:
				anim_sm.travel("wall")
				anim_tree.set("parameters/wall/blend_position",face_direction)
			_:
				anim_sm.travel("idle")
				anim_tree.set("parameters/idle/blend_position",face_direction)

func debug_text() -> void:
	var debug_text_vel = "velocity: (%.00f,%.00f)" %[velocity.x,velocity.y]
	var debug_text_pos = "position: (%.00f,%.00f)" %[global_position.x,global_position.y]
	var format_movementstates = [Move.state_name[Move.previous],
		Move.state_name[Move.current],
		Move.state_name[Move.next]]
	var debug_text_movementstates = "MOVEMENT STATES\nprev: %s\ncurrent: %s\n(next: %s)" %format_movementstates
	var debug_text_onfloor = "on floor: %s" %on_floor
	var debug_text_onwall = "on wall: %s" %on_wall
	var debug_text_canajump = "can ajump: %s" %can_ajump
	var debug_text_canadash = "can adash: %s" %can_adash
	var format_actionstates = [Action.state_name[Action.previous],
		Action.state_name[Action.current],
		Action.state_name[Action.next]]
	var debug_text_actionstates = "ACTION STATES\nprev: %s\ncurrent: %s\n(next: %s)" %format_actionstates
	
	var debug_text_health = "Player Health: %0.f/%0.f" %[stats.health,stats.max_health]
	
	if stats:
		DebugTexts.get_node("%health").text = debug_text_health
	
	DebugTexts.get_node("%velocity").text = debug_text_vel
	DebugTexts.get_node("%position").text = debug_text_pos
	DebugTexts.get_node("%movementstates").text = debug_text_movementstates
	DebugTexts.get_node("%onfloor").text = debug_text_onfloor
	DebugTexts.get_node("%onwall").text = debug_text_onwall
	DebugTexts.get_node("%canajump").text = debug_text_canajump
	DebugTexts.get_node("%canadash").text = debug_text_canadash
	DebugTexts.get_node("%actionstates").text = debug_text_actionstates
	
	var blend_pos: float = anim_tree.get("parameters/%s/blend_position" %anim_sm.get_current_node())
	
	DebugTexts.get_node("%anim_state").text = "Anim: %s (%d)" %[anim_sm.get_current_node(),blend_pos]
	
	var current_state_node = anim_sm.get_current_node()
	var travel_path = anim_sm.get_travel_path()
	
	DebugTexts.get_node("%anim_playback").text = "%s\n%s" %[current_state_node,travel_path]
