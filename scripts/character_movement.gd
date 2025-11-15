extends RigidBody2D

@export var movement_velocity := 1000.0
@export var jump_velocity := 400.0:
	get: return -jump_velocity
	
@onready var input: PlayerInput = $PlayerInput
@onready var ground_check: RayCast2D = $GroundCheck

@export var player_id := 1:
	set(id):
		player_id = id
		# DON'T set authority on self (the player body)
		# player body stays under server authority

		# ONLY set authority on the input synchronizer child node
		if has_node("PlayerInput"):
			$PlayerInput.set_multiplayer_authority(id)


func _ready() -> void:
	linear_damp = 4.0  # Acts like air resistance/friction
	lock_rotation = true  # Prevent player from rotating/falling over


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	
	var on_floor = ground_check.is_colliding()
	
	if input.consume_jump() and on_floor:
		linear_velocity.y = jump_velocity  # Or use impulse
	
	var dir = input.direction
	if dir != Vector2.ZERO:
		linear_velocity.x = dir.x * movement_velocity  # Direct control
	else:
		linear_velocity.x = lerp(linear_velocity.x, 0.0, 0.2)  # Quick sto
