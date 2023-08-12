extends ActorBase

func _ready() -> void:
	direction = 1

func _physics_process(delta: float) -> void:
	velocity.x = max_run_tile*Globals.TILE_UNITS*direction
	velocity.y = 10*Globals.TILE_UNITS
	move_and_slide()
	
	if $Node2D/ShapeCast2D.is_colliding() and direction > 0:
		direction = -$Node2D/ShapeCast2D.get_collision_normal(0).x
	elif $Node2D/ShapeCast2D2.is_colliding() and direction < 0:
		direction = -$Node2D/ShapeCast2D2.get_collision_normal(0).x
	
	if direction == 0:
		direction = 1
	pass
