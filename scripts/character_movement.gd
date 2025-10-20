extends CharacterBody2D

const SPEED := 200.0
const JUMP_VELOCITY := -400.0

@onready var input: Node = $PlayerInput

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
	velocity.x = dir.x * SPEED

	move_and_slide()
