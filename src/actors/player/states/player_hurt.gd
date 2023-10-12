extends PlayerState

@export_group("Transitions")
@export var neutral: State = null

@export_group("References")
@export var auto: State = null

func state_enter() -> void:
	super()
	print("HURT")
	player.anim_sm.travel("hurt")
	machine.partner.change_state(auto)
	Globals.freeze(0.1,0.4)

func state_animated(anim_name: StringName) -> State:
	if anim_name in ["hurt_left","hurt_right"]:
		return neutral
	return null
