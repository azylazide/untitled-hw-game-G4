## Base class to store basic actor information
##
## Stores health and general actor stats or information
extends Resource
class_name ActorResource

@export_group("General")
@export var max_health:=100.0
@export var health:= 100.0:
	set(value):
		health = clampf(value,0,max_health)
