## Region to limit the camera.
##
## Disable limits to create camera bridges among other regions.
## Bridges should have higher priority than surrounding regions
extends Area2D
class_name CameraBoundBox

## Priority to use limits of camera area against other overlapping areas.
@export var priority_level:= 0
## Bit flags for each direction to limit (Left, Right, Top, Bottom)
@export_flags("Left","Right","Top","Bottom") var limit_flags:= 0b1111

## Collision shape child of the node
@onready var collision_shape:= $CollisionShape2D

## Dictionary that stores the bounds of the collision shape in global coordinates
var limits:Dictionary = {}

func _init():
	monitoring = false
	set_collision_layer_value(1,false)
	set_collision_layer_value(Globals.CAMERA_REGION_LAYER,true)

func _ready() -> void:
	#compute limits in global coords
	limits["left"] = global_position.x-collision_shape.shape.extents.x
	limits["right"] = global_position.x+collision_shape.shape.extents.x
	limits["top"] = global_position.y-collision_shape.shape.extents.y
	limits["bottom"] = global_position.y+collision_shape.shape.extents.y
