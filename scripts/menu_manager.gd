extends Control

@export var initial_menu: Globals.MenuName = Globals.MenuName.MAIN
@export var start_with_initial: bool = true

#maybe use a menucontainer class instad of singular node for iddfferent menus
var uiLayer: Node

var menus: Dictionary[Globals.MenuName, MenuBase]
var current_menu: MenuBase


func _ready() -> void:
	initialize()


# scan inside the uiLayer for all MenuBase nodes and store them in the menus dictionary
func initialize(ui_layer: Node = null) -> void:
	if ui_layer == null:
		ui_layer = get_node("/root/Multiplayer/UILayer")
	uiLayer = ui_layer
	menus = {}
	for menu in uiLayer.get_children():
		if menu is MenuBase:
			menus[menu.menu_name] = menu
			await menu.ready
	hide_all_menus()
	if start_with_initial:
		open_initial()


func open_initial():
	show_menu(initial_menu)


func show_menu(menu_name: Globals.MenuName) -> void:
	if current_menu != null:
		current_menu.close()
	var next_menu: MenuBase = menus.get(menu_name, null)
	if next_menu != null:
		next_menu.open()
		# if current_menu != null:
		# 	print("maybe signal")
		current_menu = next_menu
	else:
		push_error("MenuManager: No menu found with name %s" % str(menu_name))


func get_current_menu() -> MenuBase:
	return current_menu


@rpc("authority", "call_local", "reliable")
func hide_all_menus() -> void:
	for menu in menus.values():
		menu.close()
	current_menu = null
