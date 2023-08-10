extends Node

@onready var player_hurt_audio: AudioStreamPlayer = $PlayerHurt

func play_hurt() -> void:
	player_hurt_audio.play()
