extends MenuBase

@onready 
var status_label: Label = $TextureRect/Panel/MarginContainer/Lobby/HBoxContainer/Label
@onready
var disconnect_button: Button = $TextureRect/Panel/MarginContainer/Lobby/HBoxContainer/DisconnectButton
@onready
var start_button: Button = $TextureRect/Panel/MarginContainer/Lobby/HBoxContainer/StartButton

@onready
var player_list: VBoxContainer = $TextureRect/Panel/MarginContainer/Lobby/PlayerInfo/PlayerList


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	disconnect_button.pressed.connect(_on_disconnect_pressed)
	Lobby.player_joined.connect(_on_player_joined_lobby)
	Lobby.player_left.connect(_on_player_left_lobby)


func _on_player_left_lobby(peer_id: int, player_info: Dictionary) -> void:
	_refresh_player_list()


func _on_player_joined_lobby(peer_id: int, player_info: Dictionary) -> void:
	_refresh_player_list()


func _on_disconnect_pressed():
	Lobby.leave_lobby()
	MenuManager.show_menu(Globals.MenuName.MAIN)


func _on_start_pressed():
	if not Lobby.is_host():
		return
	MenuManager.hide_all_menus.rpc()
	SceneManager.change_scene_multiplayer(SceneManager.Scene.GAME)


func open():
	super()
	if !Lobby.is_host():
		start_button.visible = false


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
	status_label.text = (
		"%s (%d players)" % ["Hosting" if Lobby.is_host() else "Connected", Lobby.players.size()]
	)
