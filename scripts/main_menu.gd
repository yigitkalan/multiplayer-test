extends MenuBase

@onready var username_input: TextEdit = $TextureRect/Panel/MarginContainer/Home/UsernameInput
@onready var host_button: Button = $TextureRect/Panel/MarginContainer/Home/HostButton
@onready var join_button: Button = $TextureRect/Panel/MarginContainer/Home/JoinButton
@onready var label: Label = $TextureRect/Panel/MarginContainer/Home/Label


func _ready():
	# Connect UI buttons
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	username_input.text_changed.connect(_on_username_changed)


func _on_host_pressed():
	var error = Lobby.create_game()
	if error != OK:
		label.text = "Failed to host!"
		label.modulate = Color.RED
		return
	MenuManager.show_menu(Globals.MenuName.LOBBY)


func _on_join_pressed():
	label.text = "Connecting..."
	var error = Lobby.join_game("127.0.0.1")
	if error != OK:
		label.text = "Failed to connect!"
		label.modulate = Color.RED
		return
	MenuManager.show_menu(Globals.MenuName.LOBBY)


func _on_username_changed():
	Lobby.player_info["name"] = username_input.text


func open():
	super()
	# await get_tree().process_frame
	label.text = ""
