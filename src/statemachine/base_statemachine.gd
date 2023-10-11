extends Node
class_name StateMachine

@export var pawn: Node = null

@export var initial_state: State = null

var current_state: State = null
var previous_state: State = null
var previous_frame_state: State
var next_state: State

func machine_init() -> void:
	for child in get_children():
		assert(child is State, "Invalid state child")
		print(child)
		child.pawn = pawn
		child.machine = self
		child.state_init()

	assert(initial_state is State, "Invalid initial state")
	next_state = initial_state
	change_state(initial_state)
	print("%s Current: %s" %[self,current_state])

func machine_process(delta: float) -> void:
	var new_state: State = current_state.state_process(delta)
	change_state(new_state)

func machine_physics(delta: float) -> void:
	var new_state: State = current_state.state_physics(delta)
	change_state(new_state)

func machine_input(event: InputEvent) -> void:
	var new_state: State = current_state.state_input(event)
	change_state(new_state)

func machine_on_animation_signaled(anim_name: StringName) -> void:
	var new_state: State = current_state.state_animated(anim_name)
	change_state(new_state)

func change_state(new_state: State) -> void:
	previous_frame_state = current_state
	if not new_state:
		return

	if current_state:
		previous_state = current_state
		current_state.state_exit()

	current_state = new_state
	current_state.state_enter()
