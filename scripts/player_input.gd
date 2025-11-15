class_name PlayerInput
# player_input.gd
extends Node2D

@export var direction: Vector2 = Vector2.ZERO  # Synced continuously

# Don't sync jumping at all - use RPC instead
var _jump_requested: bool = false

var _shoot_requested: bool = false
var _mouse_postition: Vector2

@onready var sync: MultiplayerSynchronizer = $InputSynchronizer

func _ready() -> void:
	set_process(sync.is_multiplayer_authority())

func _process(_delta: float) -> void:
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	set_current_mouse_pos()
	
	if Input.is_action_just_pressed("ui_accept"):
		_request_jump()
		
	if Input.is_action_just_pressed("click"):
		_request_shoot()

func _request_jump() -> void:
	if multiplayer.is_server():
		_jump_requested = true
	else:
		_request_jump_rpc.rpc_id(1)

func _request_shoot() -> void:
	set_current_mouse_pos()
	if multiplayer.is_server():
		_shoot_requested = true
	else:
		_request_shoot_rpc.rpc_id(1, _mouse_postition)

@rpc("any_peer", "call_local", "reliable")
func _request_jump_rpc() -> void:
	_jump_requested = true

@rpc("any_peer", "call_local", "reliable")
func _request_shoot_rpc(pos: Vector2) -> void:
	_shoot_requested = true
	_mouse_postition = pos

# For the server to check
func consume_jump() -> bool:
	var result = _jump_requested
	_jump_requested = false
	return result
	
#func set_current_mouse_pos() -> void:
	#_mouse_postition = get_viewport().get_mouse_position()
	
func set_current_mouse_pos() -> void:
	#var camera = get_viewport().get_camera_2d()
	#if camera:
		#_mouse_postition = camera.get_global_mouse_position()  
	_mouse_postition = get_global_mouse_position()
		
func get_click_pos() -> Vector2:
	return _mouse_postition
	
func consume_shoot() -> bool:
	var result = _shoot_requested
	_shoot_requested = false
	return result
