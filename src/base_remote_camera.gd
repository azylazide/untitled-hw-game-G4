extends Camera2D
class_name RemoteCamera
## A Camera that provides basic limits using [CameraArea]s and [CameraAreaDetector].
##
## Solves the current overlapping [CameraArea], clamps the position and interpolates it.
##
##

## [Node2D] the camera will center itself.
@export var followed_node: Node2D
## Enables or disables the automatic following of the camera.
@export var follow:= true
## Initial global position when not following [member follow] node.
@export var initial_pos:= Vector2.ZERO

@export_group("Smoothing")
## Weight for vertical interpolation.
@export var vertical_smoothing:= 0.15
## Weight for horizontal interpolation.
@export var horizontal_smoothing:= 0.15

@export_group("Editor")
## Draw on screen the clamped region and the center of the camera.
@export var debug_draw:= true

## Current [CameraArea]s overlapped for bounds calculation.
var bbox_array: Array[CameraArea] = []
## Large integer that denotes no bounds.
var bridge_inf:= limit_right

## Current bounds used by the camera.
var bounds: BoundsContainer

## Global position clamped to bounds of current [member bounds].
var clamped_pos: Vector2
## Interpolated position from [method _updated_position] to [member clamped_pos]
var interped_pos: Vector2

signal camera_area_added(area: CameraArea)
signal camera_area_removed(area: CameraArea)

## Screen size of viewport rect
@onready var screen_size:= get_viewport_rect().size
## Actual spans the camera encompasses with respect to global coordinates taking account zoom
@onready var camera_span:= Vector2(screen_size.x/zoom.x,screen_size.y/zoom.y)

class BoundsContainer:
## Class that stores limits.
	var left: int
	var right: int
	var top: int
	var bottom: int
	func _init(large_value: int) -> void:
		left = -large_value
		right = large_value
		top = -large_value
		bottom = large_value

class LimitArrayContainer:
## Class that stores an array of limits taken from [member bbox_array].
	var left: Array[int] = []
	var right: Array[int] = []
	var top: Array[int] = []
	var bottom: Array[int] = []
	## Priority of using this current bounds. Higher value is higher priority.
	var priority: Array[int] = []

func _ready() -> void:
	_setup_camera.call_deferred()
	pass
	
func _setup_camera() -> void:
	bounds = BoundsContainer.new(bridge_inf)
	if follow:
		global_position = followed_node.global_position
	else:
		global_position = initial_pos + offset

func _draw() -> void:
	if debug_draw:
		draw_circle(to_local(global_position),5,Color.WHEAT)
		_draw_camera_clamp()

## Draw clamped regions.
func _draw_camera_clamp() -> void:
	if not bbox_array.is_empty():
		if bounds.left != -bridge_inf:
			draw_line(to_local(Vector2(bounds.left+0.5*camera_span.x,global_position.y-300)),to_local(Vector2(bounds.left+0.5*camera_span.x,global_position.y+300)),Color.RED)
		if bounds.right != bridge_inf:
			draw_line(to_local(Vector2(bounds.right-0.5*camera_span.x,global_position.y-300)),to_local(Vector2(bounds.right-0.5*camera_span.x,global_position.y+300)),Color.RED)
		if bounds.top != -bridge_inf:
			draw_line(to_local(Vector2(global_position.x-300,bounds.top+0.5*camera_span.y)),to_local(Vector2(global_position.x+300,bounds.top+0.5*camera_span.y)),Color.RED)
		if bounds.bottom != bridge_inf:
			draw_line(to_local(Vector2(global_position.x-300,bounds.bottom-0.5*camera_span.y)),to_local(Vector2(global_position.x+300,bounds.bottom-0.5*camera_span.y)),Color.RED)


func _process(_delta: float) -> void:
	pass


func _physics_process(_delta: float) -> void:
	process_camera_position()

## Computes and updates the camera's [member global_position].
func process_camera_position() -> void:
	var new_pos:= _updated_position()
	bounds = _calculate_limits()
	clamped_pos = _clamp_pos(new_pos)
	interped_pos = _interp_pos(global_position)

	if follow:
		global_position = interped_pos

	if debug_draw:
		queue_redraw()

## Returns the [member global_position] with [member offset].
func _updated_position() -> Vector2:
	return followed_node.global_position + offset

## Returns [member RemoteCamera.BoundsContainer] calculated from [member bbox_array].
func _calculate_limits() -> BoundsContainer:
	## Initialize default limits.
	var default_limits: BoundsContainer = BoundsContainer.new(bridge_inf)

	## If inside a region.
	if not bbox_array.is_empty():
		var limit_arrays: LimitArrayContainer = LimitArrayContainer.new()

		## Assign to limit arrays the corresponding values, dependent on [member CameraArea.limit_flags].
		for area in bbox_array:
			limit_arrays.left.append(int(area.limits.left) if area.limit_flags & 0b1 else default_limits.left)
			limit_arrays.right.append(int(area.limits.right) if area.limit_flags & 0b1 << 1 else default_limits.right)
			limit_arrays.top.append(int(area.limits.top) if area.limit_flags & 0b1 << 2 else default_limits.top)
			limit_arrays.bottom.append(int(area.limits.bottom) if area.limit_flags & 0b1 << 3 else default_limits.bottom)

			limit_arrays.priority.append(area.priority_level)

		## Find the maximum priority among the current [CameraArea]s.
		var max_priority: int = limit_arrays.priority.max()

		var temp_limits: BoundsContainer = BoundsContainer.new(bridge_inf)
		## Assign temporary limits based on limits with corresponding maximum priority.
		temp_limits.left = limit_arrays.left[limit_arrays.priority.find(max_priority)]
		temp_limits.right = limit_arrays.right[limit_arrays.priority.find(max_priority)]
		temp_limits.top = limit_arrays.top[limit_arrays.priority.find(max_priority)]
		temp_limits.bottom = limit_arrays.bottom[limit_arrays.priority.find(max_priority)]

		## Check for multiple equal [member max_priority].
		if limit_arrays.priority.count(max_priority) > 1:
			var max_indices: Array[int] = []
			## Save the indices of the max priorities.
			for i in limit_arrays.priority.size():
				if limit_arrays.priority[i] == max_priority:
					max_indices.append(i)

			## Use the more limiting bounds.
			for i in max_indices:
				if absi(temp_limits.left) < absi(limit_arrays.left[i]):
					temp_limits.left = limit_arrays.left[i]
				if absi(temp_limits.right) < absi(limit_arrays.right[i]):
					temp_limits.right = limit_arrays.right[i]
				if absi(temp_limits.top) < absi(limit_arrays.top[i]):
					temp_limits.top = limit_arrays.top[i]
				if absi(temp_limits.bottom) < absi(limit_arrays.bottom[i]):
					temp_limits.bottom = limit_arrays.bottom[i]

		return temp_limits

	## Not inside any region.
	else:

		return default_limits

## Returns the clamped [member global_position] based on [member bounds] and [member camera_span].
func _clamp_pos(pos: Vector2) -> Vector2:
	var output:= Vector2.ZERO

	output.x = clampf(pos.x,bounds.left+0.5*camera_span.x,bounds.right-0.5*camera_span.x)
	output.y = clampf(pos.y,bounds.top+0.5*camera_span.y,bounds.bottom-0.5*camera_span.y)

	return output

## Returns the interpolated [member global_position] from current to [member clamped_pos]
## with weights of [member horizontal_smoothing] and [member vertical_smoothing].
func _interp_pos(pos: Vector2) -> Vector2:
	var output:= Vector2.ZERO

	output.x = lerpf(pos.x,clamped_pos.x,horizontal_smoothing)
	output.y = lerpf(pos.y,clamped_pos.y,vertical_smoothing)

	return output

## Appends a [CameraArea] to [member bbox_array].
## [br]Main point of entry to use the remote camera.
func append_area(area: CameraArea) -> void:
	if area is CameraArea:
		bbox_array.append(area)
		camera_area_added.emit(area)

## Removes a [CameraArea] from [member bbox_array].
## [br]Second point of entry to use the remote camera.
func remove_area(area: CameraArea) -> void:
	if area is CameraArea:
		bbox_array.erase(area)
		camera_area_removed.emit(area)
