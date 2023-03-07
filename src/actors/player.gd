extends ActorBase

@export_group("Initial Values")
## Change the initial facing direction
@export_range(-1,1) var initial_direction:= 1
## Initial movement state on ready
@export var initial_movement_state: MovementStates.STATES = MovementStates.STATES.IDLE

@export_group("Platformer Values")
## Coyote time to temporarily float in seconds
@export var coyote_time:= 0.1
## Time jump inputs are remembered just before landing from falling in seconds
@export var jump_buffer_time:= 0.1


@onready var ground_cast:= $GroundDetector

@onready var camera_bbox_detector := $CameraBBoxDetector

@onready var camera_center := $CameraCenter

## If on floor on previous frame
@onready var was_on_floor:= true

var jump_gravity: float
var min_jump_force: float
var fall_gravity: float


## If on floor on current frame
var on_floor: bool

## MovementStates object that stores states information
var Move: MovementStates

## Stores the movement states
class MovementStates:
	## Movement states
	enum STATES {IDLE,RUN,FALL,JUMP}
	const NULL:= -1
	var current: int
	var previous:= -1
	var next:= -1
	var previous_frame:= -1

func _setup_movement() -> void:
	jump_gravity = Globals._gravity(jump_height,max_run_tile,gap_length)
	fall_gravity = Globals._gravity(1.5*jump_height,max_run_tile,0.8*gap_length)
	
	jump_force = Globals._jump_vel(max_run_tile,jump_height,gap_length)
	min_jump_force = Globals._jump_vel(max_run_tile,min_jump_height,gap_length/2.0)
	
	speed = max_run_tile*Globals.TILE_UNITS
	
	face_direction = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#create movementstates object
	Move = MovementStates.new()
	Move.current = initial_movement_state
	
	_setup_movement()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
#	print(Move.current)
	pass

func _physics_process(delta: float) -> void:
	#MOVEMENT STATEMACHINE
	_movement_statemachine(delta)
	SignalBus.player_updated.emit()
	
	DebugTexts.get_node("Label").text = "velocity: (%.00f,%.00f)" %[velocity.x,velocity.y]
	DebugTexts.get_node("Label2").text = "MOVEMENT STATES\nprev: %d\ncurrent: %d\n(next: %d)" %[Move.previous,Move.current,Move.next]
	DebugTexts.get_node("Label3").text = "floor: %s" %on_floor

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
		Move.STATES.JUMP:
			_enter_jump()
	pass

## Main states code that runs per frame
func _run_movement_state(delta: float) -> int:
	
	match Move.current:
		Move.STATES.IDLE:
			var dir = get_direction()
			velocity.x = 0
			_apply_gravity(delta)
			
			was_on_floor = check_floor()
			_apply_movement(dir)
			on_floor = check_floor()
			
			if dir != 0:
				return Move.STATES.RUN
			
			if not on_floor:
				return Move.STATES.FALL
				
			return Move.STATES.IDLE
			
		Move.STATES.RUN:
			var dir = get_direction()
			velocity.x = speed*dir
			_apply_gravity(delta)
			
			was_on_floor = check_floor()
			_apply_movement(dir)
			on_floor = check_floor()
			
			if dir == 0 and on_floor:
				return Move.STATES.IDLE
			
			if not on_floor:
				return Move.STATES.FALL
				
			return Move.STATES.RUN
		
		Move.STATES.FALL:
			var dir = get_direction()
			velocity.x = speed*dir
			_apply_gravity(delta)
			
			was_on_floor = check_floor()
			_apply_movement(dir)
			on_floor = check_floor()
			
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
			
			if velocity.y > 0:
				return Move.STATES.FALL
			
			return Move.STATES.JUMP
	
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
	print("jump")
	velocity.y = -jump_force

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
	return is_on_floor()

func _unhandled_input(event: InputEvent) -> void:
	match Move.current:
		Move.STATES.IDLE:
			if event.is_action_pressed("jump"):
				if on_floor:
					change_movement_state(Move.STATES.JUMP)
		Move.STATES.RUN:
			if event.is_action_pressed("jump"):
				if on_floor:
					change_movement_state(Move.STATES.JUMP)
