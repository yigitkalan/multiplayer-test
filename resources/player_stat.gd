class_name PlayerStat
extends Resource

@export var movement_velocity: int
@export var jump_velocity: int:
	get: return -jump_velocity
