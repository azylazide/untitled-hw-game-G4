extends ActorBase

@export_group("Initial Values")
## Change the initial facing direction
@export_enum("LEFT","RIGHT") var initial_direction:= 1
## Initial movement state on ready
@export var initial_movement_state: MovementStates.STATES = MovementStates.STATES.IDLE

@export_group("Platformer Values")
@export_subgroup("Jump")
## Coyote time to temporarily float in seconds
@export var coyote_time:= 0.1
## Time jump inputs are remembered just before landing from falling in seconds
@export var jump_buffer_time:= 0.1

@export_subgroup("Dash")
## Dash duration in seconds
@export var dash_time:= 0.2
## Duration until player can dash again
@export var dash_cooldown_time:= 0.2
## Distance travelled by dash
@export var dash_length:= 2.0

@export_subgroup("Wall")
@export var wall_kick_time:= 0.5
@export var wall_kick_power:= 2.5
@export var wall_cooldown_time:= 0.2


@onready var ground_cast:= $GroundDetector

@onready var left_wall_detector:= $WallDetectors/Left

@onready var right_wall_detector:= $WallDetectors/Right

@onready var camera_bbox_detector := $CameraBBoxDetector

@onready var camera_center := $CameraCenter

@onready var coyote_timer:= $Timers/CoyoteTimer

@onready var jump_buffer_timer:= $Timers/JumpBufferTimer

@onready var dash_timer:= $Timers/DashTimer

@onready var dash_cooldown_timer:= $Timers/DashCooldownTimer

@onready var wall_slide_timer:= $Timers/WallSlideTimer

@onready var wall_cooldown_timer:= $Timers/WallCooldownTimer

@onready var wall_jump_hold_timer:= $Timers/WallJumpHoldTimer

## If on floor on previous frame
@onready var was_on_floor:= true

@onready var can_adash:= true

@onready var can_ajump:= true

@onready var wall_normal:= Vector2.ZERO

var jump_gravity: float
var min_jump_force: float
var fall_gravity: float
var dash_force: float


## If on floor on current frame
var on_floor: bool

var on_wall: bool

## MovementStates object that stores states information
var Move: MovementStates

## Stores movement states information
class MovementStates:
	## Movement states
	enum STATES {IDLE,RUN,FALL,JUMP,GDASH,ADASH,WALL}
	## Dictionary storing the names of the states in pascal case
	var state_name = STATES.keys().map(func(elem):return elem.to_pascal_case())
	const NULL:= -1
	var current: int
	var previous:= NULL
	var next:= NULL
	var previous_frame:= NULL
	
	func _init(current_state) -> void:
		current = current_state

func _setup_movement() -> void:
	jump_gravity = Globals._gravity(jump_height,max_run_tile,gap_length)
	fall_gravity = Globals._gravity(1.5*jump_height,max_run_tile,0.8*gap_length)
	
	jump_force = Globals._jump_vel(max_run_tile,jump_height,gap_length)
	min_jump_force = Globals._jump_vel(max_run_tile,min_jump_height,gap_length/2.0)
	
	speed = max_run_tile*Globals.TILE_UNITS
	
	dash_force = Globals._dash_speed(dash_length,dash_time)
	
	face_direction = 1

func _setup_timers() -> void:
	coyote_timer.wait_time = coyote_time
	jump_buffer_timer.wait_time = jump_buffer_time
	dash_timer.wait_time = dash_time
	dash_cooldown_timer.wait_time = dash_cooldown_time
	wall_slide_timer.wait_time = 0.1
	wall_cooldown_timer.wait_time = wall_cooldown_time
	wall_jump_hold_timer.wait_time = 0.5
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#create movementstates object
	Move = MovementStates.new(initial_movement_state)
	
	_setup_movement()
	_setup_timers()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	#MOVEMENT STATEMACHINE
	_movement_statemachine(delta)
	SignalBus.player_updated.emit(face_direction,camera_center.global_position)
	
	
	DebugTexts.get_node("Control/HBoxContainer/VBoxContainer/Label").text = "velocity: (%.00f,%.00f)\nposition: (%.00f,%.00f)" %[velocity.x,velocity.y,global_position.x,global_position.y]
	DebugTexts.get_node("Control/HBoxContainer/VBoxContainer/Label2").text = "MOVEMENT STATES\nprev: %s\ncurrent: %s\n(next: %s)" %[Move.state_name[Move.previous],Move.state_name[Move.current],Move.state_name[Move.next]]
	DebugTexts.get_node("Control/HBoxContainer/VBoxContainer2/Label3").text = "floor: %s\nwall: %s" %[on_floor,on_wall]
	

## Movement state machine
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
	change_movement_state(Move.next)
	pass

## Initial states that run first
func _initial_movement_state(delta: float) -> int:
	return Move.STATES.IDLE

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
	pass

## Main states code that runs per frame
func _run_movement_state(delta: float) -> int:
	
	match Move.current:
		Move.STATES.IDLE:
			var dir = get_direction()
			velocity.x = 0
			#_apply_gravity(delta)
			
			was_on_floor = check_floor()
			_apply_movement(dir)
			on_floor = check_floor()
			on_wall = check_wall()
			
			if dir != 0:
				return Move.STATES.RUN
			
			if not on_floor:
				if was_on_floor:
					coyote_timer.start()
				else:
					return Move.STATES.FALL
			
			if not jump_buffer_timer.is_stopped() and on_floor:
				jump_buffer_timer.stop()
				return Move.STATES.JUMP
			
			return Move.STATES.IDLE
			
		Move.STATES.RUN:
			var dir = get_direction()
			velocity.x = speed*dir
			#_apply_gravity(delta)
			
			was_on_floor = check_floor()
			_apply_movement(dir)
			on_floor = check_floor()
			on_wall = check_wall()
			
			if dir == 0 and on_floor:
				return Move.STATES.IDLE
			
			if not on_floor:
				if was_on_floor:
					coyote_timer.start()
				else:
					return Move.STATES.FALL
			
			if not jump_buffer_timer.is_stopped() and on_floor:
				jump_buffer_timer.stop()
				return Move.STATES.JUMP
				
			return Move.STATES.RUN
		
		Move.STATES.FALL:
			var dir = get_direction()
			velocity.x = speed*dir
			_apply_gravity(delta)
			
			was_on_floor = check_floor()
			_apply_movement(dir)
			on_floor = check_floor()
			on_wall = check_wall()
			
			#wallslide
			
			if on_floor:
				return Move.STATES.IDLE
			
			return Move.STATES.FALL
		
		Move.STATES.JUMP:
			_apply_gravity(delta)
			var dir = get_direction()
			velocity.x = speed*dir
			
			was_on_floor = check_floor()
			_apply_movement(dir)
			on_floor = check_floor()
			on_wall = check_wall()
			
			if velocity.y > 0:
				return Move.STATES.FALL
			
			return Move.STATES.JUMP
		
		Move.STATES.GDASH:
			var dir = get_direction()
			
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
						return Move.STATES.RUN
					else:
						return Move.STATES.IDLE
				elif not on_floor and not was_on_floor:
					return Move.STATES.FALL
			
			return Move.STATES.GDASH
		
		Move.STATES.ADASH:
			var dir = get_direction()
			
			was_on_floor = check_floor()
			_apply_movement(dir)
			on_floor = check_floor()
			on_wall = check_wall()
			
			if dash_timer.is_stopped():
				if on_floor:
					if dir != 0:
						return Move.STATES.RUN
					else:
						return Move.STATES.IDLE
				else:
					return Move.STATES.FALL
			
			return Move.STATES.ADASH
			
		Move.STATES.WALL:
			pass
		
	return 0

## Clean up when transitioning out to
func _exit_movement_state(delta: float, current: int) -> int:
	return 0

## Transitioning states	
func change_movement_state(next_state: int) -> void:
	Move.previous_frame = Move.current
	if next_state == Move.current:
		return
	
	Move.previous = Move.current
	Move.current = next_state

#	printt(Move.previous,Move.current)

## Setup jump
func _enter_jump() -> void:
	match Move.previous:
		Move.STATES.FALL:
			#walljump
			
			velocity.y = -jump_force*0.8
		
		_:
			velocity.y = -jump_force

## Reset values upon touching ground
func _ground_reset() -> void:
	can_adash = true
	can_ajump = true

func get_direction() -> float:
	return Input.get_axis("left","right")

func _apply_gravity(delta: float) -> void:
	if velocity.y > 0:
		velocity.y += fall_gravity*delta
		
	else:
		velocity.y += jump_gravity*delta

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
	match Move.current:
		Move.STATES.IDLE:
			if event.is_action_pressed("jump"):
				if on_floor:
					change_movement_state(Move.STATES.JUMP)
			if event.is_action_pressed("dash"):
				if dash_cooldown_timer.is_stopped():
					change_movement_state(Move.STATES.GDASH)
		Move.STATES.RUN:
			if event.is_action_pressed("jump"):
				if on_floor:
					change_movement_state(Move.STATES.JUMP)
			if event.is_action_pressed("dash"):
				if dash_cooldown_timer.is_stopped():
					change_movement_state(Move.STATES.GDASH)
		Move.STATES.JUMP:
			if event.is_action_released("jump"):
				if velocity.y < -min_jump_force:
					velocity.y = -min_jump_force
					#printt(velocity.y, "cut jump")
					change_movement_state(Move.STATES.FALL)
			if event.is_action_pressed("dash"):
				if dash_cooldown_timer.is_stopped() and can_adash:
					change_movement_state(Move.STATES.ADASH)
		Move.STATES.FALL:
			if event.is_action_pressed("jump"):
				if velocity.y > 0:
					jump_buffer_timer.start()
				if can_ajump: #and not on wall
					can_ajump = false
					jump_buffer_timer.stop()
					change_movement_state(Move.STATES.JUMP)
			if event.is_action_pressed("dash"):
				if dash_cooldown_timer.is_stopped() and can_adash:
					change_movement_state(Move.STATES.ADASH)
		Move.STATES.GDASH:
			if event.is_action_pressed("jump"):
				if on_floor:
					change_movement_state(Move.STATES.JUMP)
			if event.is_action_pressed("dash"):
				if dash_cooldown_timer.is_stopped():
					change_movement_state(Move.STATES.GDASH)
		
