extends Control

var current_layer: Node

# layers for _go_to_layer() to call
onready var main = $"menu container"
onready var settingsmenu = $"settings container"
onready var gameplaysettings = $"gameplay settings container"
onready var controls = $"controls settings container"
onready var videosettings = $"video settings container"
#onready var serverbrowser = $""
#onready var crosshairmenu

func _ready():
	current_layer = main
	for child in get_children():
		child.hide()
	main.show()
	$background.show()
	hide()
	set_process_input(false)
	# make sure all the menu icons and settings and whatnot are properly set up
	$"video settings container/Fullscreen Checker".set_pressed(OS.is_window_fullscreen())
	$"video settings container/Max FPS container/Max FPS".set_text(str(Engine.get_target_fps()))
	$"video settings container/VSync Checker".set_pressed(OS.is_vsync_enabled())


func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		match current_layer:
			main:
				_exit()
			settingsmenu:
				_go_to_layer(main)
			gameplaysettings:
				_go_to_layer(settingsmenu)
			controls:
				_go_to_layer(settingsmenu)
			videosettings:
				_go_to_layer(settingsmenu)

func _go_to_layer(layer: Node):
	layer.show()
	current_layer.hide()
	current_layer = layer

func _display():
	show()
	set_process_input(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _exit():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_process_input(false)
	# don't uncomment the hide function unless we fix the weirdo hack in the testing
	# player script at the end of the sim with inputs function LMFAO you'll see
	# what I mean there
#	hide()
	# maybe a more efficient way of doing this
	var parent = get_parent()
	parent.playerlist[parent.selfid].set_process_input(true)

#------------------------------------------------------------------------------
# Individual Button presses/////////////////////////////////////////////////////
#-------------------------------------------------------------------------------

func _on_Settings_Button_pressed():
	_go_to_layer(settingsmenu)


func _on_Server_Browser_Button_pressed():
	pass
	# _go_to_layer(serverbrowser)


func _on_Quit_Button_pressed():
	settings.save_settings()
	get_tree().quit()


func _on_Disconnect_Button_pressed():
	get_parent()._disconnect_from_server()


func _on_Gameplay_Settings_Button_pressed():
	_go_to_layer(gameplaysettings)


func _on_Controls_Settings_Button_pressed():
	_go_to_layer(controls)


func _on_Video_Settings_Button_pressed():
	_go_to_layer(videosettings)


func _on_Fullscreen_Checker_toggled(button_pressed):
	OS.set_window_fullscreen(button_pressed)
	settings.change_setting("Video Settings", "Fullscreen", button_pressed)


func _on_VSync_Checker_toggled(button_pressed):
	OS.set_use_vsync(button_pressed)
	settings.change_setting("Video Settings", "EnableV-Sync", button_pressed)


func _on_Max_FPS_text_changed(new_text):
	var maxfps = int(new_text)
	Engine.set_target_fps(maxfps)
	settings.change_setting("Video Settings", "Frameratelimit", maxfps)


func _on_Resolution_dropdown_item_selected(index):
	pass


func _on_Keybinds_Button_pressed():
	pass # Replace with function body.


func _on_Behavior_Button_pressed():
	pass # Replace with function body.


func _on_Crosshair_Button_pressed():
	pass # Replace with function body.
