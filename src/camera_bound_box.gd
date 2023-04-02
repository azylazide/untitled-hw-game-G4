@tool
## Region to limit the camera.
##
## Disable limits to create camera bridges among other regions.
## Bridges should have higher priority than surrounding regions
extends Area2D

class_name CameraBoundBox

## Priority to use limits of camera area against other overlapping areas.
@export var priority_level := 0

@export_group("Limits")
##Limit camera scrolling to the left
@export var limit_left := true
##Limit camera scrolling to the top
@export var limit_top := true
##Limit camera scrolling to the right
@export var limit_right := true
##Limit camera scrolling to the bottom
@export var limit_bottom := true

@onready var collision_shape:= $CollisionShape2D

const camera_region_mask:= 5

var limits = {}

func _reset_pos() -> void:
	if Engine.is_editor_hint():
		$CollisionShape2D.position = Vector2.ZERO

func _init():
	monitoring = false
	set_collision_layer_value(1,false)
	set_collision_layer_value(camera_region_mask,true)

func _ready() -> void:
	_reset_pos()
	limits["left"] = global_position.x-collision_shape.shape.extents.x
	limits["right"] = global_position.x+collision_shape.shape.extents.x
	limits["top"] = global_position.y-collision_shape.shape.extents.y
	limits["bottom"] = global_position.y+collision_shape.shape.extents.y
	print(limits)

func _process(delta: float) -> void:
	_reset_pos()
	pass
