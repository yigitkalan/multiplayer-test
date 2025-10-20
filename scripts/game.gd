
extends Node2D
const PLAYER_SCENE := preload("uid://b2xyd22qyvitu")
@onready var spawn_points: Array = $SpawnPoints.get_children()
@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner
var spawned_players := {}  # Track spawned player nodes {peer_id: node}
func _ready() -> void:
	# Wait for the tree to be ready
	await get_tree().process_frame

	# Make sure the spawner exists and is in the tree
	if not player_spawner:
		push_error("PlayerSpawner not found!")
		return

	# Set up the custom spawn function
	player_spawner.spawn_function = spawn_player

	# Connect to Lobby signals for join/leave
	Lobby.player_joined.connect(_on_lobby_player_joined)
	Lobby.player_left.connect(_on_lobby_player_left)

	# Spawn all players that are already in the lobby
	if multiplayer.is_server():
		for peer_id in Lobby.players.keys():
			spawn_player_for_peer(peer_id)
# Called when a player joins the lobby (even mid-game)
func _on_lobby_player_joined(peer_id: int, player_info: Dictionary):
	if not multiplayer.is_server():
		return

	print("Player %s (ID: %d) joined, spawning..." % [player_info.get("name", "Unknown"), peer_id])

	# Spawn player for the new joiner
	# Wait a moment to ensure their scene is loaded
	await get_tree().create_timer(0.5).timeout

	if not spawned_players.has(peer_id):
		spawn_player_for_peer(peer_id)
# Called when a player leaves the lobby
func _on_lobby_player_left(peer_id: int, player_info: Dictionary, reason: String):
	if not multiplayer.is_server():
		return

	print("Player %s (ID: %d) left (%s), despawning..." % [player_info.get("name", "Unknown"), peer_id, reason])

	# Despawn their player
	if spawned_players.has(peer_id):
		var player_node = spawned_players[peer_id]
		if is_instance_valid(player_node):
			player_node.queue_free()  # MultiplayerSpawner handles replication
		spawned_players.erase(peer_id)
# Spawn a single player for a specific peer
func spawn_player_for_peer(peer_id: int):
	if not multiplayer.is_server():
		return

	# Don't spawn if already spawned
	if spawned_players.has(peer_id):
		print("Player %d already spawned, skipping" % peer_id)
		return

	# Find an available spawn point
	var spawn_index = spawned_players.size() % spawn_points.size()

	var spawn_data = {
		"position": spawn_points[spawn_index].global_position,
		"peer_id": peer_id
	}

	# Use the MultiplayerSpawner to spawn - it will replicate to all clients
	var player_node = player_spawner.spawn(spawn_data)
	spawned_players[peer_id] = player_node

	print("Spawned player for peer %d at position %v" % [peer_id, spawn_data["position"]])
# Custom spawn function - called on ALL peers (server + all clients)
func spawn_player(spawn_data: Variant) -> Node:
	var player := PLAYER_SCENE.instantiate()
	var peer_id = spawn_data["peer_id"]

	# Set unique name
	player.name = "P_%s" % str(peer_id)

	# Set position
	player.global_position = spawn_data["position"]

	# Server owns the physics/movement
	player.set_multiplayer_authority(1)

	# Client owns their input
	var input_sync = player.get_node("PlayerInput/InputSynchronizer")
	input_sync.set_multiplayer_authority(peer_id)

	print("Spawned player for peer %d (I am peer %d)" % [peer_id, multiplayer.get_unique_id()])

	return player
