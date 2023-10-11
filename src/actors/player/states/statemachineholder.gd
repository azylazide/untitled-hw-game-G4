extends Node

func _ready() -> void:
	$MovementStateMachine.partner = $ActionStateMachine
	$ActionStateMachine.partner = $MovementStateMachine
