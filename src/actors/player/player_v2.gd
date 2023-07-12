extends ActorBase

@export_group("Initial Values")
## Change the initial facing direction
@export_enum("LEFT","RIGHT") var initial_direction:= 1
## Initial movement state on ready
@export var initial_movement_state: MovementStates.STATES = MovementStates.STATES.IDLE
@export var initial_action_state: ActionStates.STATES = ActionStates.STATES.NEUTRAL

@export_category("Platformer Values")
## Stores player specific movement related parameters
@export var platformer_settings: PlatformerResource

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
	
	dash_force = Globals._dash_speed(platformer_settings.dash_length,platformer_settings.dash_time)
	
	wall_kick_force = Globals._wall_kick(platformer_settings.wall_kick_power,platformer_settings.wall_kick_time)
	
	face_direction = 1

## Setup timer durations
func _setup_timers() -> void:
	coyote_timer.wait_time = platformer_settings.coyote_time
	jump_buffer_timer.wait_time = platformer_settings.jump_buffer_time
	dash_timer.wait_time = platformer_settings.dash_time
	dash_jump_buffer_timer.wait_time = platformer_settings.dash_jump_buffer_time
	dash_cooldown_timer.wait_time = platformer_settings.dash_cooldown_time
	wall_slide_timer.wait_time = 0.1
	wall_cooldown_timer.wait_time = platformer_settings.wall_cooldown_time
	wall_jump_hold_timer.wait_time = 0.5
	pass

func _setup_anim() -> void:
	anim_sm = anim_tree.get("parameters/playback")
	anim_tree.active = true

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	pass

func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	pass

func _ready_statemachine() -> void:
	#collect the states
	pass

func _physics_statemachine(delta: float) -> void:
	pass
