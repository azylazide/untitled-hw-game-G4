## Remote camera that smoothtly follows the player and is clamped by camera regions.
##
## [color=yellow]Warning:[/color] Provide the player scene with 
## a [Node2D] to be the camera center.
## [br][color=yellow]Warning:[/color] Provide the player scene with 
## an [Area2D] named CameraBBoxDetector to be the region detector.
extends Camera2D

## Player nodepath the camera follows.
@export_node_path("CharacterBody2D") var player_path

@export var x_offset_tiles := 0.8
#@export var down_bias_tiles := 0.8

@export_category("Smoothing")
@export_range(0,1) var horizontal_slow_smoothing = 0.1
@export_range(0,1) var wall_jump_smoothing = 0.1
@export_range(0,1) var horizontal_fast_smoothing = 0.15
@export_range(0,1) var vertical_slow_smoothing = 0.1
@export_range(0,1) var vertical_fast_smoothing = 0.4

## Player node to follow.
@onready var player_node: CharacterBody2D = get_node(player_path)


@onready var x_offset: float = x_offset_tiles*32

@onready var current_offset:= Vector2(x_offset,0)

@onready var screen_size = get_viewport_rect().size

## Array of nodes that stores the camera regions.
var bbox_array = []
## Default max limit greater than any camera bounds.
var bridge_inf:= 10000000

var player_facing: float
var prev_state: int
var current_state: int
var player_velocity: Vector2
var player_speed: float
var player_camera_center_pos: Vector2
var movement_states

## Dictionary that contains the max limits.
var bounds = {"left":-bridge_inf,
		"top":-bridge_inf,
		"right":bridge_inf,
		"bottom":bridge_inf}

var detector_exited:= false
## Position of the camera center according to a [Node2D] in the player scene.
var player_camera_center: Node2D


func _ready() -> void:
	
	#connect detector to camera
	player_node.camera_bbox_detector.area_entered.connect(on_CameraBBoxDetector_area_entered)
	player_node.camera_bbox_detector.area_exited.connect(on_CameraBBoxDetector_area_exited)
	player_node.camera_bbox_detector.tree_exiting.connect(on_area_detector_exiting)
	
	#connect player physics updates
	SignalBus.player_updated.connect(_on_player_node_updated)
	
	#player info
	player_facing = player_node.face_direction
	player_camera_center = player_node.camera_center
	player_camera_center_pos = player_camera_center.global_position
	
	#set initial position
	global_position = _update_position()



func _physics_process(delta: float) -> void:
	#get new position
	var new_position:= _update_position()
	#get clamped position
	var clamped_position:= _clamp_position(new_position)
	#interp new position
	var interped_position:= _interp_position(new_position,clamped_position)
	#update position
	global_position = interped_position


## Clamps position of camera within all overlapping bounding regions
## taking into account priority levels and region limit flags.
func _clamp_position(pos: Vector2) -> Vector2:
	var output: Vector2
	
	var left_limit:= -bridge_inf
	var top_limit:= -bridge_inf
	var right_limit:= bridge_inf
	var bottom_limit:= bridge_inf
	
	#when intersecting
	if not bbox_array.is_empty():
		var left_array:= []
		var top_array:= []
		var right_array:= []
		var bottom_array:= []

		var priorities:= []

		#save limits of each area in bbox array
		for area in bbox_array:
			var collision: CollisionShape2D = area.get_node("CollisionShape2D")
			var shape: RectangleShape2D = collision.shape
			var extents: Vector2 = shape.extents
			
			left_array.append(int(collision.global_position.x-extents.x) if area.limit_left else left_limit)
			top_array.append(int(collision.global_position.y-extents.y) if area.limit_top else top_limit)
			right_array.append(int(collision.global_position.x+extents.x) if area.limit_right else right_limit)
			bottom_array.append(int(collision.global_position.y+extents.y) if area.limit_bottom else bottom_limit)

			priorities.append(area.priority_level)

		#find the highest priority area
		var max_priority: int = priorities.max()

		#set temp limits
		var temp_left: int = left_array[priorities.find(max_priority)]
		var temp_top: int = top_array[priorities.find(max_priority)]
		var temp_right: int = right_array[priorities.find(max_priority)]
		var temp_bottom: int = bottom_array[priorities.find(max_priority)]

		#for duplicate high priority
		if priorities.count(max_priority) > 1:
			var max_indices = []
			for i in priorities.size():
				if priorities[i] == max_priority:
					max_indices.append(i)

			#compare which has smaller constraint
			#and set it as new temp limit
			for i in max_indices:
				if abs(temp_left) < abs(left_array[i]):
					temp_left = left_array[i]
				if abs(temp_top) < abs(top_array[i]):
					temp_top = top_array[i]
				if abs(temp_right) < abs(right_array[i]):
					temp_right = right_array[i]
				if abs(temp_bottom) < abs(bottom_array[i]):
					temp_bottom = bottom_array[i]

		#set temp limit as limit
		output.x = clamp(pos.x,temp_left+0.5*screen_size.x*zoom.x,temp_right-0.5*screen_size.x*zoom.x)
		output.y = clamp(pos.y,temp_top+0.5*screen_size.y*zoom.y,temp_bottom-0.5*screen_size.y*zoom.y)
		
		bounds.left = temp_left
		bounds.top = temp_top
		bounds.right = temp_right
		bounds.bottom = temp_bottom
		
#		print("cam: (%.00f,%.00f)\nL: %.00f R: %.00f\nT: %.00f B: %.00f" 
#				%[output.x,output.y,temp_left,temp_right,temp_top,temp_bottom])
	
	elif detector_exited:
		output.x = clamp(pos.x,bounds.left+0.5*screen_size.x*zoom.x,bounds.right-0.5*screen_size.x*zoom.x)
		output.y = clamp(pos.y,bounds.top+0.5*screen_size.y*zoom.y,bounds.bottom-0.5*screen_size.y*zoom.y)

	else:
		#set defaults
		output.x = clamp(pos.x,left_limit+0.5*screen_size.x*zoom.x,right_limit-0.5*screen_size.x*zoom.x)
		output.y = clamp(pos.y,top_limit+0.5*screen_size.y*zoom.y,bottom_limit-0.5*screen_size.y*zoom.y)
		bounds.left = left_limit
		bounds.top = top_limit
		bounds.right = right_limit
		bounds.bottom = bottom_limit

	return output

## Interpolate to new position according to smoothings set.
## [br]Dependence to movement states apply here.
func _interp_position(new_pos: Vector2, clamped_pos: Vector2) -> Vector2:
	
	var output: Vector2
	
	#horizontal
	var hs: float = horizontal_slow_smoothing
	#TODO: when player is too far from camera
	
#	#when wall jumping
#	if (prev_state == movement_states.WALL and
#		current_state == movement_states.JUMP):
#			hs = wall_jump_smoothing
#	#when slow moving and not wall jumping
#	else:
#		if abs(player_velocity.x) > player_speed*0.5:
#			hs = horizontal_fast_smoothing
	
	#vertical
	var vs: float = vertical_slow_smoothing
	#when falling
#	if current_state == movement_states.FALL:
#		vs = vertical_fast_smoothing
	vs = vertical_fast_smoothing

	output.x = lerp(global_position.x,clamped_pos.x,hs/zoom.x)
	output.y = lerp(global_position.y,clamped_pos.y,vs/zoom.y)
	
	print("cam: (%.00f,%.00f)\nclamp: (%.00f,%.00f)\nbounds: L=%.00f R=%.00f\n        T=%.00f B=%.00f"
		%[output.x,output.y,clamped_pos.x,clamped_pos.y,bounds.left,bounds.right,bounds.top,bounds.bottom])
	
	return output

## Append camera region node to [member bbox_array].
func on_CameraBBoxDetector_area_entered(area: Area2D) -> void:
	bbox_array.append(area)

## Remove camera region node from [member bbox_array].
func on_CameraBBoxDetector_area_exited(area: Area2D) -> void:
	bbox_array.erase(area)

func on_area_detector_exiting() -> void:
	detector_exited = true
	
## Update stored player information after its physics step.
func _on_player_node_updated(facing: float, cam_pos: Vector2) -> void:
	
	player_facing = facing
	player_camera_center_pos = cam_pos
	
	pass

func _get_offset() -> Vector2:
	var face_dir: float = player_facing
	var output:= current_offset
	if face_dir > 0:
		output.x = x_offset
	elif face_dir < 0:
		output.x = -x_offset
	return output

func _update_position() -> Vector2:
	current_offset = _get_offset()
	return player_camera_center_pos + current_offset
