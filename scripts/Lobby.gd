extends Node
# Autoload named Lobby

# Unified signals - no duplication
signal player_joined(peer_id: int, player_info: Dictionary)
signal player_left(peer_id: int, player_info: Dictionary, reason: String)
signal server_closed()

const PORT = 7000
const DEFAULT_SERVER_IP = "127.0.0.1"
const MAX_CONNECTIONS = 20

var players = {}
var player_info = {"name": "Name"}
var players_loaded = 0

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func is_host() -> bool:
	return multiplayer.is_server()

func is_in_lobby() -> bool:
	return multiplayer.multiplayer_peer != null and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer

func get_local_peer_id() -> int:
	return multiplayer.get_unique_id() if is_in_lobby() else 0

func create_game() -> int:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CONNECTIONS)
	if error:
		return error
	
	multiplayer.multiplayer_peer = peer
	players[1] = player_info
	player_joined.emit(1, player_info)
	return OK

func join_game(address: String = "") -> int:
	if address.is_empty():
		address = DEFAULT_SERVER_IP
	
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, PORT)
	if error:
		return error
	
	multiplayer.multiplayer_peer = peer
	return OK

func leave_lobby():
	if not is_in_lobby():
		return
	
	var my_id = get_local_peer_id()
	var my_info = player_info.duplicate()
	
	if is_host():
		# Host is leaving - close the entire server
		_broadcast_server_closing.rpc()
		await get_tree().create_timer(0.1).timeout
	else:
		# Client leaving - notify server
		_notify_graceful_leave.rpc_id(1, my_info)
		await get_tree().create_timer(0.1).timeout
	
	# Clean up and emit locally
	_cleanup()
	player_left.emit(my_id, my_info, "left_gracefully")

# ============================================================================
# MULTIPLAYER CALLBACKS
# ============================================================================

func _on_peer_connected(id: int):
	# Send my info to the newly connected peer
	_register_player.rpc_id(id, player_info)

func _on_peer_disconnected(id: int):
	# Someone disconnected (could be graceful or crash)
	if players.has(id):
		var disconnected_info = players[id]
		players.erase(id)
		player_left.emit(id, disconnected_info, "disconnected")

func _on_connected_to_server():
	# I successfully connected as a client
	var my_id = get_local_peer_id()
	players[my_id] = player_info
	player_joined.emit(my_id, player_info)

func _on_connection_failed():
	_cleanup()

func _on_server_disconnected():
	_cleanup()
	server_closed.emit()

# ============================================================================
# RPCs
# ============================================================================

@rpc("any_peer", "call_remote", "reliable")
func _register_player(new_player_info: Dictionary):
	# Received when a new player connects
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_joined.emit(new_player_id, new_player_info)

@rpc("any_peer", "call_remote", "reliable")
func _notify_graceful_leave(leaving_player_info: Dictionary):
	# Server receives this when a client leaves gracefully
	if not is_host():
		return
	
	var leaving_id = multiplayer.get_remote_sender_id()
	
	# Broadcast to everyone (including server) that this player left
	_broadcast_player_left.rpc(leaving_id, leaving_player_info)

@rpc("authority", "call_local", "reliable")
func _broadcast_player_left(peer_id: int, player_info_data: Dictionary):
	# Everyone (including host) receives this
	if players.has(peer_id):
		players.erase(peer_id)
	player_left.emit(peer_id, player_info_data, "left_gracefully")

@rpc("authority", "call_local", "reliable")
func _broadcast_server_closing():
	# Host is shutting down the server
	_cleanup()
	server_closed.emit()

# ============================================================================
# GAME LOADING (for when you start the actual game)
# ============================================================================

@rpc("authority", "call_local", "reliable")
func load_game(game_scene_path: String):
	get_tree().change_scene_to_file(game_scene_path)

@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	if not is_host():
		return
	
	players_loaded += 1
	if players_loaded == players.size():
		# All players loaded - start the game
		# $/root/Game.start_game()  # Uncomment when you have this
		players_loaded = 0

# ============================================================================
# INTERNAL
# ============================================================================

func _cleanup():
	players.clear()
	players_loaded = 0
	
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
