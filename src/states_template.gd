extends RefCounted
class_name StateContainer

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
