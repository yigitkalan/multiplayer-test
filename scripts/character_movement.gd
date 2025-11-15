extends CharacterBody2D

const SPEED := 10000.0
const JUMP_VELOCITY := -400.0

@onready var input: PlayerInput = $PlayerInput

@export var player_id := 1:
	set(id):
		player_id = id
		# DON'T set authority on self (the player body)
		# player body stays under server authority

		# ONLY set authority on the input synchronizer child node
		if has_node("PlayerInput"):
			$PlayerInput.set_multiplayer_authority(id)


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return

	if not is_on_floor():
		velocity.y += get_gravity().y * delta

	if input.consume_jump() and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var dir = input.direction
	if dir != Vector2.ZERO:
		dir = dir.normalized()
	velocity.x = dir.x * SPEED * delta

	move_and_slide()
