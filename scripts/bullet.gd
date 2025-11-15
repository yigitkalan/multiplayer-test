class_name Bullet
extends RigidBody2D

var self_velocity : Vector2
@onready var timer: Timer = $Timer
@onready var area_2d: Area2D = $Area2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer.start()
	gravity_scale = 0.0
	linear_velocity = self_velocity
	timer.timeout.connect(kill_bullet)
	area_2d.body_entered.connect(kill_bullet_with_target)

	
func kill_bullet():
	if multiplayer.is_server():
		queue_free()
	
func kill_bullet_with_target(target: Node):
	timer.stop()
	if multiplayer.is_server():
		queue_free()
		
func set_velocity(velocity: Vector2):
	self_velocity = velocity


func _on_body_entered(body: Node) -> void:
	print("AAAAAAAAAAAAAAAAAAAAAAA")
