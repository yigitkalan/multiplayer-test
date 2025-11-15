extends Node2D

@onready var player_input: PlayerInput = $"../PlayerInput"
@onready var bullet_spawner: MultiplayerSpawner = $"../BulletSpawner"
@export var BULLET_VELOCITY := 400
const BULLET_SCENE = preload("uid://ssa5260nc2ff")

var next_bullet_direction: Vector2
@onready var shooting_point: Marker2D = $ShootingPoint

func _ready() -> void:
	set_process(multiplayer.is_server())
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player_input.consume_shoot():
		_spawn_bullet(_calculate_bullet_speed(player_input.get_click_pos()))
	look_at(player_input.get_click_pos())
	

func _spawn_bullet(bullet_velocity: Vector2) -> void:
	if not multiplayer.is_server():
		return
	var bullet : Bullet = BULLET_SCENE.instantiate()
	bullet.global_position = shooting_point.global_position
	bullet.set_velocity(bullet_velocity)
	bullet_spawner.add_child(bullet, true)
		
func _calculate_bullet_speed(click_pos: Vector2) -> Vector2:
	# click_pos should already be in world coordinates
	var dir: Vector2 = (click_pos - global_position).normalized()	
	return dir * BULLET_VELOCITY
	
func _calculate_spawn_position() -> Vector2:
	return global_position + next_bullet_direction * 5000
	
