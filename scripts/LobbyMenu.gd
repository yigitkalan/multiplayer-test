extends HBoxContainer

@onready var host_button: Button = $Menu/HostButton
@onready var join_button: Button = $Menu/JoinButton
@onready var disconnect_button: Button = $Menu/DisconnectButton
@onready var label: Label = $Menu/Label
@onready var players_info: Label = $PlayersInfo
@onready var text_edit: TextEdit = $Menu/TextEdit

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
	
	_show_in_lobby("Hosting lobby...")

func _on_join_pressed() -> void:
	var error = Lobby.join_game("127.0.0.1")
	if error != OK:
		label.text = "Failed to join!"
		return
	
	label.text = "Connecting..."
	_hide_menu_buttons()

func _on_disconnect_pressed() -> void:
	Lobby.leave_lobby()

func _on_username_changed() -> void:
	Lobby.player_info["name"] = text_edit.text

# ============================================================================
# LOBBY CALLBACKS
# ============================================================================

func _on_player_joined(peer_id: int, player_info: Dictionary) -> void:
	var player_name = player_info.get("name", "Unknown")
	_add_log("%s joined" % player_name)
	
	# Update status for local player
	if peer_id == Lobby.get_local_peer_id():
		if Lobby.is_host():
			label.text = "Hosting (%d players)" % Lobby.players.size()
		else:
			label.text = "Connected (%d players)" % Lobby.players.size()
		_show_disconnect_button()
	else:
		# Update player count
		_update_player_count()

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
	host_button.visible = true
	join_button.visible = true
	disconnect_button.visible = false
	label.text = "Main Menu"
	players_info.text = ""

func _show_in_lobby(status_text: String) -> void:
	_hide_menu_buttons()
	_show_disconnect_button()
	label.text = status_text

func _hide_menu_buttons() -> void:
	host_button.visible = false
	join_button.visible = false

func _show_disconnect_button() -> void:
	disconnect_button.visible = true

func _update_player_count() -> void:
	if Lobby.is_host():
		label.text = "Hosting (%d players)" % Lobby.players.size()
	else:
		label.text = "Connected (%d players)" % Lobby.players.size()

func _add_log(message: String) -> void:
	if players_info.text.is_empty():
		players_info.text = message
	else:
		players_info.text += "\n" + message
