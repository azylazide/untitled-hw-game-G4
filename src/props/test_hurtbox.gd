extends GeneralHurtBox


func _on_body_entered(body: Node2D) -> void:
	print("HURT YOU")
	apply_effect(body)
	pass # Replace with function body.
