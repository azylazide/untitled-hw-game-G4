extends Area2D

@export var tile_speed:= 20.0
@export var direction:= 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var coll: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	if direction < 0:
		sprite.flip_h = true
		sprite.offset.x = -10
		coll.position.x = -coll.position.x


func _physics_process(delta: float) -> void:
	global_position.x += tile_speed*Globals.TILE_UNITS*delta*direction
	pass


func _on_body_entered(body: Node2D) -> void:
	queue_free()
	pass # Replace with function body.


func _on_area_entered(area: Area2D) -> void:
	queue_free()
	pass # Replace with function body.


func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	queue_free()
	pass # Replace with function body.
