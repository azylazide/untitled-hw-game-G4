extends State
class_name PlayerState

var player: Player

func state_init() -> void:
	super()
	player = pawn as Player
