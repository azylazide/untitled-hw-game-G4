extends Sprite2D

var sprite: Sprite2D
var pos: Vector2

func _ready() -> void:
	pos = sprite.global_position

	texture = sprite.texture
	scale = sprite.scale
	hframes = sprite.hframes
	vframes = sprite.vframes
	frame_coords = sprite.frame_coords
	flip_h = sprite.flip_h
	flip_v = sprite.flip_v
	offset = sprite.offset
	global_position = pos
	z_as_relative = true
	z_index = -1

	var tween:= create_tween()
	tween.tween_property(self,"modulate:a",0,0.5).set_trans(Tween.TRANS_QUART)
	tween.tween_callback(queue_free)

func _process(delta: float) -> void:
	global_position = pos
