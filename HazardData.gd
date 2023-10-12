extends Resource
class_name HazardData

const DAMAGE:= 0b1
const STATUS:= 0b10

@export_flags("DAMAGE","STATUS") var hazard_flags:= DAMAGE

@export var do_knockback:= true
@export var knockback_strength:= 10.0
@export var knockback_vector:= Vector2.ZERO

@export var do_damage:= true
@export var damage_strength:= 10.0
