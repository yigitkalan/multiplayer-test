
# player_input.gd
extends Node

@export var direction: Vector2 = Vector2.ZERO  # Synced continuously
# Don't sync jumping at all - use RPC instead
var _jump_requested: bool = false

@onready var sync: MultiplayerSynchronizer = $InputSynchronizer

func _ready() -> void:
	set_process(sync.is_multiplayer_authority())

func _process(_delta: float) -> void:
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_action_just_pressed("ui_accept"):
		_request_jump()

func _request_jump():
	if multiplayer.is_server():
		# If we're the server, set it directly
		_jump_requested = true
	else:
		# If we're a client, tell the server
		_jump_rpc.rpc_id(1)

@rpc("any_peer", "call_local", "reliable")
func _jump_rpc():
	_jump_requested = true

# For the server to check
func consume_jump() -> bool:
	var result = _jump_requested
	_jump_requested = false
	return result
