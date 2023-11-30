extends PlayerState

@export_group("Transitions")
@export var hurt: State = null
@export var attack: State = null

func state_enter() -> void:
	super()

func state_input(event: InputEvent) -> State:
	if event.is_action_pressed("attack"):
		if (player.stats.shot_attacks & 0b10):
			player.attack_charge_timer.start()

	if event.is_action_released("attack"):
		return attack

	return null
