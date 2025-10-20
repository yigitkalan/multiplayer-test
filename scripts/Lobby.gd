
extends Node
# Autoload named Lobby

signal player_joined(peer_id: int, player_info: Dictionary)
signal player_left(peer_id: int, player_info: Dictionary, reason: String)
signal server_closed()

const PORT := 7000
const DEFAULT_SERVER_IP := "127.0.0.1"
const MAX_CONNECTIONS := 20

var players: Dictionary = {}  # {peer_id: player_info}
var player_info: Dictionary = {"name": "Name"}

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
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
	return multiplayer.multiplayer_peer != null and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer)

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
	
	var my_id := get_local_peer_id()
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

func _on_peer_connected(id: int) -> void:
	# Only server needs to do anything here
	if not multiplayer.is_server():
		return
	
	# New peer connected - they'll send their info via RPC
	print("Peer %d connected (waiting for registration)" % id)

func _on_peer_disconnected(id: int) -> void:
	# Only server handles disconnections
	if not multiplayer.is_server():
		return
	
	# Player crashed or lost connection (not graceful)
	if players.has(id):
		var info = players[id]
		players.erase(id)
		
		# Notify everyone (including server)
		_player_left_broadcast.rpc(id, info, "disconnected")

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

# Client → Server: "Here's my player info"
@rpc("any_peer", "call_remote", "reliable")
func _register_player(info: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	
	var peer_id := multiplayer.get_remote_sender_id()
	players[peer_id] = info
	
	print("Player %d registered: %s" % [peer_id, info.get("name", "Unknown")])
	
	# Emit locally on server
	player_joined.emit(peer_id, info)
	
	# Tell ALL clients (including the new one) about this player
	_player_joined_broadcast.rpc(peer_id, info)
	
	# Tell the NEW client about ALL existing players
	for existing_id in players.keys():
		if existing_id != peer_id:  # Don't send them their own info again
			_player_joined_broadcast.rpc_id(peer_id, existing_id, players[existing_id])

# Server → All: "A player joined"
@rpc("authority", "call_remote", "reliable")
func _player_joined_broadcast(peer_id: int, info: Dictionary) -> void:
	players[peer_id] = info
	player_joined.emit(peer_id, info)

# Server → All: "A player left"
@rpc("authority", "call_local", "reliable")
func _player_left_broadcast(peer_id: int, info: Dictionary, reason: String) -> void:
	players.erase(peer_id)
	player_left.emit(peer_id, info, reason)

# Client → Server: "I'm leaving gracefully"
@rpc("any_peer", "call_remote", "reliable")
func _client_leaving(info: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	
	var peer_id := multiplayer.get_remote_sender_id()
	players.erase(peer_id)
	
	# Notify everyone (including server)
	_player_left_broadcast.rpc(peer_id, info, "left_gracefully")

# Server → All: "Server is shutting down"
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
