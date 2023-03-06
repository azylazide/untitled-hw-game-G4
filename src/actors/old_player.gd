extends CharacterBody2D


@onready var camera_bbox_detector := $CameraBBoxDetector
@onready var camera_center := $CameraCenter

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var face_direction := 1.0


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	if direction == 0:
		SignalBus.player_updated.emit(0,camera_center.global_position)
		return
	else:
		face_direction = -1 if direction < 0 else 1
	
	SignalBus.player_updated.emit(face_direction,camera_center.global_position)
