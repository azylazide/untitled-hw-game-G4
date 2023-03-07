extends Node

const TILE_UNITS:= 64.0

func _gravity(h: float, vx: float, x: float) -> float:
	var output: float = 2*(h*TILE_UNITS*pow(vx*TILE_UNITS,2))/(pow(x*TILE_UNITS/2.0,2))
	return output

func _jump_vel(walk_length: float, h: float, x: float) -> float:
	var output: float = (2*h*TILE_UNITS*walk_length*TILE_UNITS)/(x*TILE_UNITS/2.0)
	return output

func _dash_speed(dash_length: float, dash_time: float) -> float:
	return dash_length*TILE_UNITS/dash_time
	
func _wall_kick(wall_kick_power: float, wall_kick_time: float):
	return wall_kick_power*TILE_UNITS/wall_kick_time
