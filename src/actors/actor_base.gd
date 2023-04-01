## Base class for actors
class_name ActorBase
extends CharacterBody2D

@export_category("Movement Values")
## Run speed in tiles per second 
@export var max_run_tile:= 6.25
## Terminal fall speed in tiles per second 
@export var max_fall_tile:= 15.0
## Jump speed in tiles per second 
@export var jump_height:= 5.5
## Interrupted jump speed in tiles per second 
@export var min_jump_height:= 0.5
## Max length of gap for a leap
@export var gap_length:= 12.5

## Current direction of movement
var direction: float
## Current facing direction
var face_direction: float
## Movement speed
var speed: float
## Jump speed
var jump_force: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
