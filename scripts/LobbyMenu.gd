extends Control

@onready var home: VBoxContainer = $TextureRect/Panel/SubMenus/Home
@onready var lobby: HBoxContainer = $TextureRect/Panel/SubMenus/Lobby

@onready var start_game: Button = $TextureRect/Panel/SubMenus/Lobby/HBoxContainer/StartGame
@onready var players_info: VBoxContainer = $TextureRect/Panel/SubMenus/Lobby/PlayerInfo
@onready var join_button: Button = $TextureRect/Panel/SubMenus/Home/JoinButton
@onready var disconnect_button: Button = $TextureRect/Panel/SubMenus/Lobby/HBoxContainer/DisconnectButton
@onready var host_button: Button = $TextureRect/Panel/SubMenus/Home/HostButton
@onready var text_edit: TextEdit = $TextureRect/Panel/SubMenus/Home/TextEdit
@onready var label: Label = $TextureRect/Panel/SubMenus/Lobby/HBoxContainer/Label
@onready var players: Label = $TextureRect/Panel/SubMenus/Lobby/PlayerInfo/Players
func _ready() -> void:
	# Connect UI
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	disconnect_button.pressed.connect(_on_disconnect_pressed)
	text_edit.text_changed.connect(_on_username_changed)
	
	# Connect Lobby signals
	Lobby.player_joined.connect(_on_player_joined)
	Lobby.player_left.connect(_on_player_left)
	Lobby.server_closed.connect(_on_server_closed)
	
	# Initial state
	_show_main_menu()

# ============================================================================
# UI CALLBACKS
# ============================================================================

func _on_host_pressed() -> void:
	var error = Lobby.create_game()
	if error != OK:
		label.text = "Failed to host!"
		return
	_show_lobby_menu()
	

func _on_join_pressed() -> void:
	label.text = "Connecting..."
	var error = Lobby.join_game("127.0.0.1")
	if error != OK:
		label.text = "Failed to join!"
		return
	_show_lobby_menu()

func _on_disconnect_pressed() -> void:
	Lobby.leave_lobby()
	_show_main_menu()

func _on_username_changed() -> void:
	Lobby.player_info["name"] = text_edit.text

# ============================================================================
# LOBBY CALLBACKS
# ============================================================================

func _on_player_joined(peer_id: int, player_info: Dictionary) -> void:
	var player_name = player_info.get("name", "Unknown")
	# Update status for local player
	if peer_id == Lobby.get_local_peer_id():
		players.text = ""
		if Lobby.is_host():
			start_game.visible = true
			label.text = "Hosting (%d players)" % Lobby.players.size()
		else:
			start_game.visible = false
			label.text = "Connected (%d players)" % Lobby.players.size()
		_show_disconnect_button()
		players_info.visible = true
	else:
		_update_player_count()
	_add_log("%s joined" % player_name)

func _on_player_left(peer_id: int, player_info: Dictionary, reason: String) -> void:
	var player_name = player_info.get("name", "Unknown")
	
	# Different messages based on reason
	match reason:
		"left_gracefully":
			_add_log("%s left" % player_name)
		"disconnected":
			_add_log("%s disconnected" % player_name)
	
	# If it's me leaving, return to main menu
	if peer_id == Lobby.get_local_peer_id():
		_show_main_menu()
	else:
		_update_player_count()

func _on_server_closed() -> void:
	_add_log("Server closed")
	_show_main_menu()

# ============================================================================
# UI HELPERS
# ============================================================================

func _show_main_menu() -> void:
	home.visible = true
	lobby.visible = false
	label.text = "Main Menu"
	
func _show_lobby_menu() -> void:
	home.visible = false
	lobby.visible = true
	if Lobby.is_host():
		start_game.visible = true
	else:
		start_game.visible = false
	

func _show_disconnect_button() -> void:
	disconnect_button.visible = true

func _update_player_count() -> void:
	if Lobby.is_host():
		label.text = "Hosting (%d players)" % Lobby.players.size()
	else:
		label.text = "Connected (%d players)" % Lobby.players.size()

func _add_log(message: String) -> void:
	if players.text.is_empty():
		players.text = message
	else:
		players.text += "\n" + message
