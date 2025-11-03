extends Control

class_name MenuBase

@export var menu_name: Globals.MenuName


#Can override if want to add animations, vfx, sfx etc.
func open():
	show()


#Can override if want to add animations, vfx, sfx etc.4
func close():
	hide()
