extends Area2D
class_name CameraArea
## An [Area2D] that dictates the limits of [RemoteCamera].
##
## Holds information necessary to clamp [RemoteCamera] as well as its priority in the calculation.
##
##

## Priority of using this area's limits. Higher value is higher priority.
@export var priority_level:= 0
## Enable or disable clamping the [RemoteCamera] in the corresponding side.
## [br]First bit is Left, then Right, Top, and Bottom.
@export_flags("Left","Right","Top","Bottom") var limit_flags:= 0b1111

## The [CollisionShape2D] to use.
@export var collision: CollisionShape2D

class LimitContainer:
## Basic container for saving the limits on each side.
	var left: float
	var right: float
	var top: float
	var bottom: float

## The limits defined for this area.
var limits: LimitContainer

func _init():
	monitoring = false
	limits = LimitContainer.new()
	set_collision_layer_value(1,false)
	set_collision_layer_value(Globals.CAMERA_REGION_LAYER,true)

func _ready() -> void:
	set_limits()

## Compute the limits for each side in global coordinates based on the [member CollisionShape2D.shape] rectangular boundary.
func set_limits() -> void:
	#compute limits in global coords
	limits.left = collision.global_position.x-collision.shape.get_rect().size.x*0.5
	limits.right = collision.global_position.x+collision.shape.get_rect().size.x*0.5
	limits.top = collision.global_position.y-collision.shape.get_rect().size.y*0.5
	limits.bottom = collision.global_position.y+collision.shape.get_rect().size.y*0.5
