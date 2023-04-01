## Base class to store basic actor information
##
## Stores health and general actor stats or information
extends Resource
class_name ActorResource

@export var max_health:=100.0
@export var health:= 100.0:
	set(value):
		value = clampf(value,0,max_health)
