
extends Control
# Attached to UILayer/PersistentHUD

@onready var connection_status: Label = $ConnectionStatus
@onready var notification_panel: PanelContainer = $NotificationPanel

func _ready():
	# Connect to Lobby signals
	Lobby.player_joined.connect(_on_player_joined)
	Lobby.player_left.connect(_on_player_left)
	Lobby.server_closed.connect(_on_server_closed)
	
	# Initial state
	connection_status.text = ""
	notification_panel.visible = false

func _on_player_joined(peer_id: int, player_info: Dictionary):
	# Only show for OTHER players joining
	if peer_id != Lobby.get_local_peer_id():
		show_notification("%s joined" % player_info.get("name", "Player"))
	
	# Update connection status
	if Lobby.is_in_lobby():
		connection_status.text = "Players: %d" % Lobby.players.size()

func _on_player_left(peer_id: int, player_info: Dictionary, reason: String):
	show_notification("%s left" % player_info.get("name", "Player"))
	
	if Lobby.is_in_lobby():
		connection_status.text = "Players: %d" % Lobby.players.size()
	else:
		connection_status.text = ""

func _on_server_closed():
	show_notification("Server closed", Color.RED)
	connection_status.text = ""
	
	# Return to lobby menu
	SceneManager.change_scene(SceneManager.Scene.LOBBY_MENU)

func show_notification(message: String, color: Color = Color.WHITE):
	notification_panel.visible = true
	var label = notification_panel.get_node_or_null("Label")
	if not label:
		label = Label.new()
		label.name = "Label"
		notification_panel.add_child(label)
	
	label.text = message
	label.modulate = color
	
	# Auto-hide after 3 seconds
	await get_tree().create_timer(3.0).timeout
	notification_panel.visible = false
