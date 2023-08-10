extends ActorResource
class_name PlayerResource

@export_flags("DASH","AJUMP","WALL") var abilities:= 0b111
@export_flags("NORMAL","CHARGED") var shot_attacks:= 0b11

@export var hurt_time:= 0.8
#attacks and inventory

#temp function
func set_ability(ability: String, enable: bool) -> void:
	match ability:
		"DASH":
			abilities = abilities | 0b1 if enable else abilities & ~0b1
		"AJUMP":
			abilities = abilities | 0b010 if enable else abilities & ~0b010
		"WALL":
			abilities = abilities | 0b100 if enable else abilities & ~0b100
	print(abilities)
