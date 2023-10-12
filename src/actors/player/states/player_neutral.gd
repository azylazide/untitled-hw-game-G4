extends PlayerState

@export_group("Transitions")
@export var hurt: State = null

func state_enter() -> void:
	super()
