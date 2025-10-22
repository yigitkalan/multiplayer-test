# level.gd
extends Node2D

const PLAYER_SCENE := preload("uid://b2xyd22qyvitu")
@onready var spawn_points: Array = $SpawnPoints.get_children()
@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner

var spawned_players := {}

func _ready() -> void:
	await get_tree().process_frame
	
	Lobby.player_joined.connect(_on_lobby_player_joined)
	Lobby.player_left.connect(_on_lobby_player_left)
	
	if multiplayer.is_server():
		for peer_id in Lobby.players.keys():
			spawn_player_for_peer(peer_id)

func _on_lobby_player_joined(peer_id: int, player_info: Dictionary):
	if not multiplayer.is_server():
		return
	await get_tree().create_timer(0.5).timeout
	if not spawned_players.has(peer_id):
		spawn_player_for_peer(peer_id)

func _on_lobby_player_left(peer_id: int, player_info: Dictionary, reason: String):
	if not multiplayer.is_server():
		return
	if spawned_players.has(peer_id):
		var player_node = spawned_players[peer_id]
		if is_instance_valid(player_node):
			player_node.queue_free()
		spawned_players.erase(peer_id)

func spawn_player_for_peer(peer_id: int):
	if not multiplayer.is_server():
		return
	
	if spawned_players.has(peer_id):
		return
	
	print("SPAWNING PLAYER: ", peer_id)
	
	# Instantiate directly - NO spawner.spawn()!
	var player := PLAYER_SCENE.instantiate()
	player.name = "P_%s" % str(peer_id)
	
	# Set position
	var spawn_index = spawned_players.size() % spawn_points.size()
	player.global_position = spawn_points[spawn_index].global_position
	
	# Set authorities
	player.set_multiplayer_authority(1)  # Server owns physics
	var input_sync = player.get_node("PlayerInput")
	input_sync.set_multiplayer_authority(peer_id)  # Client owns input
	
	# Add to tree - automatic spawning happens here
	$Players.add_child(player, true)
	spawned_players[peer_id] = player
