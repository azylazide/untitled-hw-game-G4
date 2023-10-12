## General hazard area that applies damage
extends Area2D
class_name GeneralHurtBox

@export var hazard_data: HazardData

## Sends hazard data to intersecting object. Override to add custom effects
func apply_effect(obj: Node2D) -> void:
	if obj.has_method("apply_hurtbox_effect"):
		obj.apply_hurtbox_effect(hazard_data)
