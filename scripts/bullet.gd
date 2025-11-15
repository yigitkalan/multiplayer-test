class_name Bullet
extends RigidBody2D

var self_velocity : Vector2
@export var bullet_stat: BulletStat
@onready var timer: Timer = $Timer
@onready var damage_area: Area2D = $DamageArea
@onready var kick_back_area: Area2D = $KickBackArea

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gravity_scale = 0.0
	linear_velocity = self_velocity
	
	timer.wait_time = bullet_stat.lifetime
	timer.start()
	
	set_area_range(damage_area, bullet_stat.damage_range)
	set_area_range(kick_back_area, bullet_stat.kick_back_range)
	
	timer.timeout.connect(destroy_bullet_with_time)
	body_entered.connect(destroy_bullet_with_target)

	
func destroy_bullet_with_time():
	if multiplayer.is_server():
		queue_free()
	
func destroy_bullet_with_target(target: Node):
	if target is Player:
		target.player_health.take_damage(bullet_stat.damage)
		pass
		
	timer.stop()
	if multiplayer.is_server():
		queue_free()
		
func set_velocity(velocity: Vector2):
	self_velocity = velocity
	


func set_area_range(area: Area2D, range: float) -> void:
	for child in area.get_children():
		if child is CollisionShape2D:
			var shape = child.shape
			if shape is CircleShape2D:
				shape.radius = range 
