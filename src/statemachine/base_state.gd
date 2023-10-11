extends Node
class_name State

var pawn: Node
var machine: StateMachine


func state_init() -> void:
	set_physics_process(false)
	set_process(false)
	set_process_input(false)
	pass

func state_enter() -> void:
	set_physics_process(true)
	set_process(true)
	set_process_input(true)
	pass

func state_exit() -> void:
	set_physics_process(false)
	set_process(false)
	set_process_input(false)
	pass

func state_physics(delta: float) -> State:
	return null

func state_process(delta: float) -> State:
	return null

func state_input(event: InputEvent) -> State:
	return null

func state_animated(anim_name: StringName) -> State:
	return null
