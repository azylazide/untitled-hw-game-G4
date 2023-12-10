extends Node2D
class_name ProjectileSpawnerManager

@export var player: Player
@export var arrow_pscn: PackedScene

func _ready() -> void:
	player.player_attacked.connect(spawn_arrow)

func spawn_arrow(dir: float) -> void:
	var arrow_scn:= arrow_pscn.instantiate()
	arrow_scn.direction = dir
	add_child(arrow_scn)
	arrow_scn.global_position = player.global_position
	# FIXME
	player.attack_finished = true
	pass
