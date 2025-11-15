extends Node
# Autoload named Lobby

signal player_joined(peer_id: int, player_info: Dictionary)
signal player_left(peer_id: int, player_info: Dictionary)
signal server_closed

const PORT := 7000
const DEFAULT_SERVER_IP := "127.0.0.1"
const MAX_CONNECTIONS := 20

var players: Dictionary = {}  # {peer_id: player_info}
var player_info: Dictionary = {"name": "Name"}


func _ready():
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


# ============================================================================
# PUBLIC API
# ============================================================================


func is_host() -> bool:
	return multiplayer.is_server()


func is_in_lobby() -> bool:
	return (
		multiplayer.multiplayer_peer != null
		and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer)
	)


func get_local_peer_id() -> int:
	return multiplayer.get_unique_id() if is_in_lobby() else 0


func create_game() -> int:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, MAX_CONNECTIONS)
	if error:
		return error

	multiplayer.multiplayer_peer = peer

	# Host registers locally
	players[1] = player_info
	player_joined.emit(1, player_info)
	return OK


func join_game(address: String = "") -> int:
	if address.is_empty():
		address = DEFAULT_SERVER_IP

	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, PORT)
	if error:
		return error

	multiplayer.multiplayer_peer = peer
	return OK


func leave_lobby():
	if not is_in_lobby():
		return

	var my_info := player_info.duplicate(true)

	if is_host():
		# Host closing = everyone disconnects
		_server_shutdown.rpc()
	else:
		# Client leaving gracefully
		_client_leaving.rpc_id(1, my_info)

	await get_tree().create_timer(0.1).timeout
	_cleanup()


# ============================================================================
# MULTIPLAYER CALLBACKS
# ============================================================================


func _on_peer_disconnected(id: int) -> void:
	# Only server handles disconnections
	if not multiplayer.is_server():
		return

	# Player crashed or lost connection (not graceful)
	if players.has(id):
		var info = players[id]
		players.erase(id)

		# Notify everyone (including server)
		_player_left_broadcast.rpc(id, info)


func _on_connected_to_server() -> void:
	# Client successfully connected - send our info
	_register_player.rpc_id(1, player_info)


func _on_connection_failed() -> void:
	_cleanup()


func _on_server_disconnected() -> void:
	_cleanup()
	server_closed.emit()


# ============================================================================
# RPCs
# ============================================================================

@rpc("any_peer", "call_remote", "reliable")
func _register_player(info: Dictionary) -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	players[peer_id] = info

	# Emit locally on server
	player_joined.emit(peer_id, info)

	# Tell ALL clients (including the new one) about this player
	_player_joined_broadcast.rpc(peer_id, info)

	# Tell the NEW client about ALL existing players
	for existing_id in players.keys():
		if existing_id != peer_id:  # Don't send them their own info again
			_player_joined_broadcast.rpc_id(peer_id, existing_id, players[existing_id])


@rpc("authority", "call_remote", "reliable")
func _player_joined_broadcast(peer_id: int, info: Dictionary) -> void:
	players[peer_id] = info
	player_joined.emit(peer_id, info)


@rpc("authority", "call_local", "reliable")
func _player_left_broadcast(peer_id: int, info: Dictionary) -> void:
	players.erase(peer_id)
	player_left.emit(peer_id, info)


@rpc("any_peer", "call_remote", "reliable")
func _client_leaving(info: Dictionary) -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	players.erase(peer_id)

	# Notify everyone (including server)
	_player_left_broadcast.rpc(peer_id, info)


@rpc("authority", "call_local", "reliable")
func _server_shutdown() -> void:
	_cleanup()
	server_closed.emit()


# ============================================================================
# INTERNAL
# ============================================================================


func _cleanup() -> void:
	players.clear()

	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
