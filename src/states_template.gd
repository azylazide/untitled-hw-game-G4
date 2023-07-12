## Basic template for storing states machine information

extends RefCounted
class_name StateContainer

## Dictionary storing the names of the states in pascal case
var state_name = {}
## Null state
const NULL:= -2
## Auto state
const AUTO:= -1
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
	var temp_name = enum_dic.keys().map(func(elem):return elem.to_pascal_case())
	state_name[-2] = "Null"
	state_name[-1] = "Auto"
	var i:= 0
	for state in temp_name:
		state_name[i] = state
		i+=1
	
func change_state() -> void:
	self.previous_frame = self.current
	if self.next == self.current:
		return
	
	self.previous = self.current
	self.current = self.next
