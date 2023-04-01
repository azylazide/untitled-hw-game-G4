## Basic template for storing states machine information

extends RefCounted
class_name StateContainer

## Dictionary storing the names of the states in pascal case
var state_name = {}
## Null state
const NULL:= -1
## Current frame state
var current: int
## Previous set state
var previous:= NULL
## Next state to set
var next:= NULL
## Previous frame state that can be same as the current state
var previous_frame:= NULL

func _init(current_state) -> void:
	current = current_state

func _name_dict(enum_dic) -> void:
	state_name = enum_dic.keys().map(func(elem):return elem.to_pascal_case())
