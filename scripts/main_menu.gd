
extends Control

# Main Menu
@onready var main_menu: VBoxContainer = $TextureRect/Panel/SubMenus/Home
@onready var username_input: TextEdit = $TextureRect/Panel/SubMenus/Home/TextEdit
@onready var host_button: Button = $TextureRect/Panel/SubMenus/Home/HostButton
@onready var join_button: Button = $TextureRect/Panel/SubMenus/Home/JoinButton

# Lobby
@onready var lobby_container: HBoxContainer = $TextureRect/Panel/SubMenus/Lobby
@onready var status_label: Label = $TextureRect/Panel/SubMenus/Lobby/HBoxContainer/Label
@onready var player_list: Label = $TextureRect/Panel/SubMenus/Lobby/PlayerInfo/Players
@onready var start_button: Button = $TextureRect/Panel/SubMenus/Lobby/HBoxContainer/StartGame
@onready var disconnect_button: Button = $TextureRect/Panel/SubMenus/Lobby/HBoxContainer/DisconnectButton

func _ready():
	# Connect UI buttons
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	start_button.pressed.connect(_on_start_pressed)
	disconnect_button.pressed.connect(_on_disconnect_pressed)
	username_input.text_changed.connect(_on_username_changed)
	
	# Connect Lobby signals
	Lobby.player_joined.connect(_on_player_joined)
	Lobby.player_left.connect(_on_player_left)
	
	# Initial state
	_show_main_menu()

# ============================================================================
# UI BUTTON CALLBACKS
# ============================================================================

func _on_host_pressed():
	var error = Lobby.create_game()
	if error != OK:
		status_label.text = "Failed to host!"
		status_label.modulate = Color.RED
		return
	
	_show_lobby()

func _on_join_pressed():
	status_label.text = "Connecting..."
	var error = Lobby.join_game("127.0.0.1")
	if error != OK:
		status_label.text = "Failed to connect!"
		status_label.modulate = Color.RED
		return
	# Wait for connection signal
	# _show_lobby() will be called by _on_player_joined

func _on_disconnect_pressed():
	Lobby.leave_lobby()
	_show_main_menu()

func _on_start_pressed():
	if not Lobby.is_host():
		return
	
	# Tell everyone to load the game scene
	SceneManager.change_scene_multiplayer(SceneManager.Scene.GAME)

func _on_username_changed():
	Lobby.player_info["name"] = username_input.text

# ============================================================================
# LOBBY SIGNAL CALLBACKS
# ============================================================================

func _on_player_joined(peer_id: int, player_info: Dictionary):
	# If it's me joining, show lobby UI
	if peer_id == Lobby.get_local_peer_id():
		_show_lobby()
	
	# Update player list
	_refresh_player_list()

func _on_player_left(peer_id: int, player_info: Dictionary, reason: String):
	# If it's me leaving, handled by disconnect button
	if peer_id == Lobby.get_local_peer_id():
		_show_main_menu()
		return
	
	# Update player list
	_refresh_player_list()

# ============================================================================
# UI STATE MANAGEMENT
# ============================================================================

func _show_main_menu():
	main_menu.visible = true
	lobby_container.visible = false
	status_label.text = ""
	status_label.modulate = Color.WHITE

func _show_lobby():
	main_menu.visible = false
	lobby_container.visible = true
	
	# Update UI based on role
	if Lobby.is_host():
		status_label.text = "Hosting"
		start_button.visible = true
	else:
		status_label.text = "Connected"
		start_button.visible = false
	
	status_label.modulate = Color.GREEN
	_refresh_player_list()

func _refresh_player_list():
	# Clear existing entries
	for child in player_list.get_children():
		child.queue_free()
	
	# Add current players
	for peer_id in Lobby.players.keys():
		var player_info = Lobby.players[peer_id]
		var entry = Label.new()
		entry.text = player_info.get("name", "Player %d" % peer_id)
		
		# Highlight local player
		if peer_id == Lobby.get_local_peer_id():
			entry.text += " (You)"
			entry.modulate = Color.YELLOW
		
		# Show host
		if peer_id == 1:
			entry.text += " [Host]"
		
		player_list.add_child(entry)
	
	# Update count
	status_label.text = "%s (%d players)" % [
		"Hosting" if Lobby.is_host() else "Connected",
		Lobby.players.size()
		]
