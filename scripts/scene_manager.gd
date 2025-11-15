extends Node
# Autoload named SceneManager

signal scene_changing(from_path: String, to_path: String)
signal scene_changed(scene_path: String)

enum Scene {
	GAME
}

const SCENE_PATHS = {
	# Scene.LOBBY_MENU: "res://scenes/main_menu.tscn",
	Scene.GAME: "res://scenes/game.tscn"
}

var current_scene: Node = null
var scene_container: Node = null
var level_spawner : MultiplayerSpawner = null

func _ready():
	# Wait for root scene to be ready
	await get_tree().process_frame

	# Get reference to the container
	scene_container = get_node("/root/Multiplayer/SceneContainer")
	# Lobby.server_closed.connect()
	
	level_spawner = get_node("/root/Multiplayer/LevelSpawner")
	
	level_spawner.spawned.connect(_on_spawned)


# Local scene change (single-player or menus)
func change_scene(scene: Scene):
	var scene_path = SCENE_PATHS[scene]
	_load_scene.call_deferred(scene_path)


# Multiplayer scene change (server tells everyone)
func change_scene_multiplayer(scene: Scene):
	if not Lobby.is_host():
		push_error("Only host can change scenes!")
		return

	var scene_path = SCENE_PATHS[scene]
#	_change_scene_for_all.rpc(scene_path)
	_load_scene.call_deferred(scene_path)

func _on_spawned(level: Node) -> void:
	MenuManager.hide_all_menus()	

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
	scene_container.add_child(new_scene, true)
	current_scene = new_scene

	scene_changed.emit(scene_path)
