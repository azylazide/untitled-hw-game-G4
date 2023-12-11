extends Area2D
class_name CameraAreaDetector

func _ready() -> void:
	set_collision_mask_value(Globals.CAMERA_REGION_LAYER,true)
