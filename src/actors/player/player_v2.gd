extends ActorBase
class_name Player

@export_group("Initial Values")
## Change the initial facing direction
@export_enum("LEFT","RIGHT") var initial_direction:= 1
## Initial movement state on ready
@export var initial_movement_state: PlayerState
## Initial action state on ready
@export var initial_action_state: PlayerState

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

## Timer that determines if fully charged or interrupted
#@onready var attack_charge_timer:= $Timers/AttackChargeTimer as Timer

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

## Statemachine
@onready var movement_sm: StateMachine = $StateMachinesHolder/MovementStateMachine
@onready var action_sm: StateMachine = $StateMachinesHolder/ActionStateMachine


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

var anim_sm: AnimationNodeStateMachinePlayback

## bool state changed by signal
var attack_finished:= true

signal player_dead
signal player_hurt
signal player_attacked

var is_dead:= false
var is_hurt:= false
var is_attack_charged:= false

var ghost_tweener: Tween

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

## Setup [AnimationTree]
func _setup_anim() -> void:
	anim_sm = anim_tree.get("parameters/playback")
	anim_tree.active = true

func _ready() -> void:
	_setup_movement()
	_setup_timers()
	_setup_anim()

	movement_sm.initial_state = initial_movement_state
	movement_sm.machine_init()
	action_sm.machine_init()
	pass

func _physics_process(delta: float) -> void:
	movement_sm.machine_physics(delta)
	action_sm.machine_physics(delta)
	_resolve_animations()

	SignalBus.player_updated.emit(face_direction,camera_center.global_position,velocity,movement_sm.current_state,null)
	debug_text()
	pass

func _unhandled_input(event: InputEvent) -> void:
	movement_sm.machine_input(event)
	pass

func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	movement_sm.machine_on_animation_signaled(anim_name)
	action_sm.machine_on_animation_signaled(anim_name)
	pass

## Resolves blend position of some blendspaces
func _resolve_animations() -> void:
	var anim_list:= ["idle","run","fall","jump","land","gdash","adash","wall","hurt"]
	for anim_name in anim_list:
		anim_tree.set("parameters/%s/blend_position" %anim_name,face_direction)

## Returns current input direction
func get_direction() -> float:
	return Input.get_axis("left","right")

## Applies move and slide and updates face_direction
func apply_movement(dir: float) -> void:
	move_and_slide()

	if dir == 0:
		return
	else:
		face_direction = -1 if dir < 0 else 1

## Checks floor or in coyote time
func check_floor() -> bool:
	return is_on_floor() or not coyote_timer.is_stopped()

## Calculate gravity applied depending on areal state
func apply_gravity(delta: float) -> void:
	if velocity.y > 0:
		velocity.y += fall_gravity*delta

	else:
		velocity.y += jump_gravity*delta

	velocity.y = minf(velocity.y,max_fall_speed)

## Checks wall and updates wall_normal
func check_wall() -> bool:
	var left: bool = left_wall_detector.is_colliding()
	var right: bool = right_wall_detector.is_colliding()

	if left and right:
		wall_normal = Vector2(-face_direction,0)
		return true
	elif left:
		wall_normal = left_wall_detector.get_collision_normal(0)
		return true
	elif right:
		wall_normal = right_wall_detector.get_collision_normal(0)
		return true
	else:
		return false

func ground_reset() -> void:
	can_ajump = true
	can_adash = true

func jump_reset() -> void:
	coyote_timer.stop()
	jump_buffer_timer.stop()

#TEMP
func hurt(i):
	action_sm.change_state($StateMachinesHolder/ActionStateMachine/Hurt)

func debug_text() -> void:
	var debug_text_vel = "velocity: (%.00f,%.00f)" %[velocity.x,velocity.y]
	var debug_text_pos = "position: (%.00f,%.00f)" %[global_position.x,global_position.y]

	var format_movementstates = [movement_sm.previous_state.name,movement_sm.current_state.name]

	var debug_text_movementstates = "MOVEMENT STATES\nprev: %s\ncurrent: %s" %format_movementstates
	var debug_text_onfloor = "on floor: %s" %on_floor
	var debug_text_onwall = "on wall: %s" %on_wall
	var debug_text_canajump = "can ajump: %s" %can_ajump
	var debug_text_canadash = "can adash: %s" %can_adash

#	var debug_text_actionstates = "ACTION STATES\nprev: %s\ncurrent: %s\n(next: %s)" %format_actionstates

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

#	DebugTexts.get_node("%is_hurt").text = "is hurt: %s" %is_hurt
#	DebugTexts.get_node("%is_dead").text = "is dead: %s" %is_dead
#	DebugTexts.get_node("%is_attack_charged").text = "is attack charged: %s" %is_attack_charged

#	DebugTexts.get_node("%actionstates").text = debug_text_actionstates

	var blend_pos: float = anim_tree.get("parameters/%s/blend_position" %anim_sm.get_current_node())

	DebugTexts.get_node("%anim_state").text = "Anim: %s (%d)" %[anim_sm.get_current_node(),blend_pos]

	var current_state_node = anim_sm.get_current_node()
	var travel_path = anim_sm.get_travel_path()
	var anim_playing = anim_sm.is_playing()

	DebugTexts.get_node("%anim_playback").text = "%s\n%s\nPlaying: %s" %[current_state_node,travel_path,anim_playing]

