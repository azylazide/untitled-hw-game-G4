extends LevelTemplate

@export var player_node: ActorBase
@export var arrow_pscn: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	player_node.player_attacked.connect(spawn_arrow)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func spawn_arrow(face_direction: float) -> void:
	print("ATTACKED")
	var arrow_scn = arrow_pscn.instantiate()
	arrow_scn.direction = face_direction
	arrow_scn.global_position = player_node.get_node("ArrowSpawn").global_position
	add_child(arrow_scn)

	pass
