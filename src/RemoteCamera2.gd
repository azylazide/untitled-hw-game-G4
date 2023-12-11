## Remote camera that smoothtly follows the player and is clamped by camera regions.
##
## [color=yellow][b]Warning[/b]:[/color] Provide the player scene with
## a [Node2D] to be the camera center.
## [br][color=yellow][b]Warning[/b]:[/color] Provide the player scene with
## an [Area2D] named CameraBBoxDetector to be the region detector.
## [br]
## [br]The remote camera must do the ff:
## [br] -Idle position with slight bias
## [br] -Vertical lerp and snap
## [br] -Horizontal strong and weak lerps
## [br] -Camera contextually bounded
## [br]
extends Camera2D
class_name RemoteCamera2old

## Player node the camera follows.
@export var player: ActorBase
## Enable camera following player
@export var follow_player:= true
## Initial position when not following player
@export var initial_pos:= Vector2.ZERO
## Fraction of tiles to offset
@export var x_offset_tiles := 0.8

@export_category("Smoothing")
@export_range(0,1) var horizontal_slow_smoothing:= 0.1
@export_range(0,1) var wall_jump_smoothing:= 0.1
@export_range(0,1) var horizontal_fast_smoothing:= 0.15
@export_range(0,1) var vertical_slow_smoothing:= 0.1
@export_range(0,1) var vertical_fast_smoothing:= 0.4

## Array of nodes that stores [CameraBoundBox]
var bbox_array: Array[CameraArea] = []
## Default max limit greater than any camera bounds
var bridge_inf:= limit_right

## Dictionary that stores the current bounds used by the camera for each direction (left, right, top, bottom)
var bounds: Dictionary = {
	"left":-bridge_inf,
	"right":bridge_inf,
	"top":-bridge_inf,
	"bottom":bridge_inf}

## Current clamped position of the camera
var clamped_pos: Vector2
## Current interpolated position of the camera
var interped_pos: Vector2

## Store face direction of [member player]
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

## Screen size of viewport rect
@onready var screen_size:= get_viewport_rect().size
## Actual spans the camera encompasses with respect to global coordinates taking account zoom
@onready var camera_span:= Vector2(screen_size.x/zoom.x,screen_size.y/zoom.y)
## Offset in pixels
@onready var x_offset: float = x_offset_tiles*Globals.TILE_UNITS
## Position of offset
@onready var current_offset:= Vector2(x_offset,0)
## Screen shake flag
@onready var screen_shake:= false

@onready var shake_offset:= Vector2.ZERO

func _ready() -> void:
	_setup_camera.call_deferred()

## Connect relevant signals, and initialized player informations
func _setup_camera() -> void:
	player.camera_bbox_detector.area_entered.connect(on_CameraBBoxDetector_area_entered)
	player.camera_bbox_detector.area_exited.connect(on_CameraBBoxDetector_area_exited)
	player.camera_bbox_detector.tree_exiting.connect(on_area_detector_exiting)

	#connect player physics updates
	SignalBus.player_updated.connect(_on_player_node_updated)
	SignalBus.screen_shake_requested.connect(_on_screen_shake_requested)

	#player info
	player_facing = player.face_direction

	randomize()

func _physics_process(delta: float) -> void:
	#Get new position of player camera marker
	var new_pos:= _update_position()
	#Get position clamped based on the region
	clamped_pos = _clamp_pos(new_pos)
	#Get interpolated values to clamped position
	interped_pos = _interp_pos(new_pos)
	#Set interpolated position as new camera position
	global_position = interped_pos
	queue_redraw()

	var debug_string = "cam: (%.00f,%.00f) C(%.00f,%.00f)\nL: %.00f R: %.00f\nT: %.00f B: %.00f"
	var format_array = [interped_pos.x,
						interped_pos.y,
						clamped_pos.x,
						clamped_pos.y,
						bounds.left,
						bounds.right,
						bounds.top,
						bounds.bottom]

	DebugTexts.get_node("%camera").text = debug_string %format_array

## Get new camera target position
func _update_position() -> Vector2:
	current_offset = _get_offset()
	if screen_shake:
		shake_tween = create_tween()
		shake_tween.tween_property(self,"shake_offset",compute_shake_offset(20),0.1)
		player_camera_center_pos+= shake_offset
	return player_camera_center_pos + current_offset

## Clamp the target position
func _clamp_pos(pos: Vector2) -> Vector2:
	var output: Vector2

	## Default limits
	var default_limits = {"left":-bridge_inf,"right":bridge_inf,"top":-bridge_inf,"bottom":bridge_inf}

	#when intersecting a BBox
	if not bbox_array.is_empty():
		#Array to store boundaries of intersecting BBoxes
		var limit_arrays = {"left":[],"right":[],"top":[],"bottom":[],"priority":[]}

		#Append each BBox's boundaries to the array inside the dictionary
		#If limit flag is false, append the default instead
		#Append also the priority level of the current iterated BBox
		for area in bbox_array:
			limit_arrays.left.append(int(area.limits.left) if area.limit_flags & 0b1000 else default_limits.left)
			limit_arrays.right.append(int(area.limits.right) if area.limit_flags & 0b0100 else default_limits.right)
			limit_arrays.top.append(int(area.limits.top) if area.limit_flags & 0b0010 else default_limits.top)
			limit_arrays.bottom.append(int(area.limits.bottom) if area.limit_flags & 0b0001 else default_limits.bottom)

			limit_arrays.priority.append(area.priority_level)

		#Find the highest value of priority
		var max_priority: int = limit_arrays.priority.max()

		#Temporarily store the boundaries with the highest corresponding priority
		var temp_limits = {"left":limit_arrays.left[limit_arrays.priority.find(max_priority)],
							"right":limit_arrays.right[limit_arrays.priority.find(max_priority)],
							"top":limit_arrays.top[limit_arrays.priority.find(max_priority)],
							"bottom":limit_arrays.bottom[limit_arrays.priority.find(max_priority)]}

		#Check if multiple BBoxes have same max priority
		if limit_arrays.priority.count(max_priority) > 1:
			#Array storing the indices of similar max priority
			var max_indices = []
			#Search the indices of same max priority
			for i in limit_arrays.priority.size():
				if limit_arrays.priority[i] == max_priority:
					max_indices.append(i)

			#loop through all max indices
			#Check if the current iterated index corresponds to the most limiting region
			#Overwrite the temp limits if iterated index is more limiting
			for i in max_indices:
				if abs(temp_limits.left) < abs(limit_arrays.left[i]):
					temp_limits.left = limit_arrays.left[i]
				if abs(temp_limits.right) < abs(limit_arrays.right[i]):
					temp_limits.right = limit_arrays.right[i]
				if abs(temp_limits.top) < abs(limit_arrays.top[i]):
					temp_limits.top = limit_arrays.top[i]
				if abs(temp_limits.bottom) < abs(limit_arrays.bottom[i]):
					temp_limits.bottom = limit_arrays.bottom[i]

		#Clamp the values up to half the camera span from the boundaries
		output.x = clampf(pos.x,temp_limits.left+0.5*camera_span.x,temp_limits.right-0.5*camera_span.x)
		output.y = clampf(pos.y,temp_limits.top+0.5*camera_span.y,temp_limits.bottom-0.5*camera_span.y)

		#Store the temp limits
		bounds.left = temp_limits.left
		bounds.right = temp_limits.right
		bounds.top = temp_limits.top
		bounds.bottom = temp_limits.bottom


	#if detector exited when player is freed
	elif detector_exited:
		output.x = clampf(pos.x,bounds.left+0.5*camera_span.x,bounds.right-0.5*camera_span.x)
		output.y = clampf(pos.y,bounds.top+0.5*camera_span.y*zoom.y,bounds.bottom-0.5*camera_span.y)

	#not intersecting a BBox
	else:
		#Clamp using default limits
		output.x = clampf(pos.x,default_limits.left+0.5*camera_span.x,default_limits.right-0.5*camera_span.x)
		output.y = clampf(pos.y,default_limits.top+0.5*camera_span.y,default_limits.bottom-0.5*camera_span.y)

		#Store default limits
		bounds.left = default_limits.left
		bounds.right = default_limits.right
		bounds.top = default_limits.top
		bounds.bottom = default_limits.bottom

	return output

func _interp_pos(pos: Vector2) -> Vector2:
	var output: Vector2

	if screen_shake:
		return clamped_pos

	var hs:= horizontal_slow_smoothing
	var vs:= vertical_slow_smoothing

	if not detector_exited:
		if prev_state and current_state:
			if prev_state.name == "Wall" and current_state.name == "Jump":
				hs = wall_jump_smoothing
			else:
				if abs(player_velocity.x) > player.speed*0.5:
					hs = horizontal_fast_smoothing

			if current_state.name == "Fall" and player_velocity.y == player.max_fall_speed:
				vs = lerpf(current_vs,vertical_fast_smoothing,0.1)

	current_hs = hs
	current_vs = vs

	output.x = lerpf(global_position.x,clamped_pos.x,hs)
	output.y = lerpf(global_position.y,clamped_pos.y,vs)


	return output

func _get_offset() -> Vector2:
	var face_dir: float = player_facing
	var output:= current_offset
	if face_dir > 0:
		output.x = x_offset
	elif face_dir < 0:
		output.x = -x_offset

	return output

## Append [CameraBoundBox] node to [member bbox_array].
func on_CameraBBoxDetector_area_entered(area: Area2D) -> void:
	bbox_array.append(area)

## Remove [CameraBoundBox] node from [member bbox_array].
func on_CameraBBoxDetector_area_exited(area: Area2D) -> void:
	bbox_array.erase(area)

## When [member player] is queue freed and its [CameraBBoxDetector] exits the tree
func on_area_detector_exiting() -> void:
	detector_exited = true

## Update stored [member player] information after its physics step.
func _on_player_node_updated(facing: float, cam_pos: Vector2, velocity: Vector2, move: State, action: State) -> void:
	player_facing = facing
	player_camera_center_pos = cam_pos
	player_velocity = velocity
	prev_state = current_state
	current_state = move

func compute_shake_offset(intensity: float) -> Vector2:
	var output = Vector2(randf_range(-1,1)*intensity,randf_range(-1,1)*intensity)
	return output

func _on_screen_shake_requested(duration: float) -> void:
	screen_shake = true
	var tween:= create_tween()
	await tween.tween_interval(duration).finished
	screen_shake = false
	shake_offset = Vector2.ZERO
	pass
