
extends Node
# Autoload named SceneManager

signal scene_changing(from_path: String, to_path: String)
signal scene_changed(scene_path: String)

enum Scene {
	LOBBY_MENU,
	GAME
}

const SCENE_PATHS = {
	Scene.LOBBY_MENU: "res://scenes/main_menu.tscn",
	Scene.GAME: "res://scenes/game.tscn"
}

var current_scene: Node = null
var scene_container: Node = null

func _ready():
	# Wait for root scene to be ready
	await get_tree().process_frame
	
	# Get reference to the container
	scene_container = get_node("/root/Multiplayer/SceneContainer")
	
	# Load initial scene
	change_scene(Scene.LOBBY_MENU)
	
	# Sync scene to late joiners
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(_on_peer_connected_scene_sync)

func _on_peer_connected_scene_sync(peer_id: int):
	# Tell the new peer to load the current scene
	if current_scene and current_scene.scene_file_path != SCENE_PATHS.get(Scene.LOBBY_MENU):
		var current_path = current_scene.scene_file_path
		_tell_client_to_load_scene.rpc_id(peer_id, current_path)

# Local scene change (single-player or menus)
func change_scene(scene: Scene):
	var scene_path = SCENE_PATHS[scene]
	_load_scene(scene_path)

# Multiplayer scene change (server tells everyone)
func change_scene_multiplayer(scene: Scene):
	if not Lobby.is_host():
		push_error("Only host can change scenes!")
		return
	
	var scene_path = SCENE_PATHS[scene]
	_change_scene_for_all.rpc(scene_path)

# Server tells everyone to change scene (including itself)
@rpc("authority", "call_local", "reliable")
func _change_scene_for_all(scene_path: String):
	_load_scene(scene_path)

# Server tells a specific client to load a scene (for late joiners)
@rpc("authority", "call_remote", "reliable")
func _tell_client_to_load_scene(scene_path: String):
	_load_scene(scene_path)

func _load_scene(scene_path: String):
	var old_path = ""
	
	# Remove current scene
	if current_scene:
		old_path = current_scene.scene_file_path
		scene_changing.emit(old_path, scene_path)
		current_scene.queue_free()
		await current_scene.tree_exited
	
	# Load new scene
	var new_scene = load(scene_path).instantiate()
	scene_container.add_child(new_scene)
	current_scene = new_scene
	
	scene_changed.emit(scene_path)
	print("Scene changed: %s → %s" % [old_path, scene_path])
