extends RemoteCamera
class_name PlayerRemoteCamera
## Extends [RemoteCamera] to interface or override functions.
##
## Player's [CameraAreaDetector] signals can interface here
## Make sure that the [CameraAreaDetector] only masks [CameraArea]'s layer.

## Connect relevant signals, and initialized player informations

## Fraction of tiles to offset
@export var x_offset_tiles := 0.8

@export_category("Smoothing")
@export_range(0,1) var horizontal_slow_smoothing:= 0.1
@export_range(0,1) var wall_jump_smoothing:= 0.1
@export_range(0,1) var horizontal_fast_smoothing:= 0.15
@export_range(0,1) var vertical_slow_smoothing:= 0.1
@export_range(0,1) var vertical_fast_smoothing:= 0.4

## Store face direction of followed [Player]
var player_facing: float
var prev_state: State
var current_state: State
var player_velocity: Vector2
var player_speed: float
var player_camera_center_pos: Vector2
var movement_states
var detector_exited:= false

var shake_tween: Tween

## Current horizontal camera smoothing
@onready var current_hs = horizontal_slow_smoothing
@onready var current_vs = vertical_slow_smoothing

## Offset in pixels
@onready var x_offset: float = x_offset_tiles*Globals.TILE_UNITS
## Position of offset
@onready var current_offset:= Vector2(x_offset,0)
## Screen shake flag
@onready var screen_shake:= false

@onready var shake_offset:= Vector2.ZERO

func _setup_camera_properties() -> void:
	followed_node.camera_bbox_detector.area_entered.connect(_on_camera_detector_area_entered)
	followed_node.camera_bbox_detector.area_exited.connect(_on_camera_detector_area_exited)
	followed_node.camera_bbox_detector.tree_exiting.connect(on_area_detector_exiting)

	#connect player physics updates
	SignalBus.player_updated.connect(_on_player_node_updated)
	SignalBus.screen_shake_requested.connect(_on_screen_shake_requested)

	#player info
	player_facing = followed_node.face_direction

func _ready() -> void:
	_setup_camera.call_deferred()
	_setup_camera_properties.call_deferred()

## Override [member _updated_position] with custom center and offset.
func _updated_position() -> Vector2:
	return player_camera_center_pos + current_offset

func _physics_process(delta: float) -> void:
	current_offset = _get_offset()
	choose_smoothing()
	process_camera_position()
	
	update_debug_text.call_deferred()

func update_debug_text() -> void:
	var debug_string = "cam: (%.00f,%.00f) C(%.00f,%.00f)\nL: %.00f R: %.00f\nT: %.00f B: %.00f"
	var format_array = [global_position.x,global_position.y,clamped_pos.x,clamped_pos.y,bounds.left,bounds.right,bounds.top,bounds.bottom]

	DebugTexts.get_node("%camera").text = debug_string %format_array


func _get_offset() -> Vector2:
	var face_dir: float = player_facing
	var output:= current_offset
	if face_dir > 0:
		output.x = x_offset
	elif face_dir < 0:
		output.x = -x_offset

	return output

func choose_smoothing() -> void:
	var hs:= horizontal_slow_smoothing
	var vs:= vertical_slow_smoothing

	if not detector_exited:
		if prev_state and current_state:
			if prev_state.name == "Wall" and current_state.name == "Jump":
				hs = wall_jump_smoothing
			else:
				if abs(player_velocity.x) > followed_node.speed*0.5:
					hs = horizontal_fast_smoothing

			if current_state.name == "Fall" and player_velocity.y == followed_node.max_fall_speed:
				vs = lerpf(current_vs,vertical_fast_smoothing,0.1)
	
	horizontal_smoothing = hs
	vertical_smoothing = vs

func _on_camera_detector_area_entered(area: Area2D) -> void:
	append_area(area)

func _on_camera_detector_area_exited(area: Area2D) -> void:
	remove_area(area)

## When [member followed_node] is queue freed and its [CameraAreaDetector] exits the tree
func on_area_detector_exiting() -> void:
	detector_exited = true

## Update stored [Player] information after its physics step.
func _on_player_node_updated(facing: float, cam_pos: Vector2, velocity: Vector2, move: State, action: State) -> void:
	player_facing = facing
	player_camera_center_pos = cam_pos
	player_velocity = velocity
	prev_state = current_state
	current_state = move

#TODO
func _on_screen_shake_requested(duration: float) -> void:
	screen_shake = true
	var tween:= create_tween()
	await tween.tween_interval(duration).finished
	screen_shake = false
	shake_offset = Vector2.ZERO
