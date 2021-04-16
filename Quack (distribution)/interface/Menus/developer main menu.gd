extends Control

#sets up quick references to buttons and such
onready var main = $main
onready var launch_main_button = $"main/Main Button"
onready var launch_devlevel_button = $"main/Devlevel Button"
onready var settings_button = $"main/Settings Button"
onready var settings_menu = $Settings
onready var crosshair_menu = $CrosshairItems
onready var video_settings_menu = $"Video Settings"
onready var sens = $"Settings/Sensitivity Container/Sensitivity Readout"
onready var plugintest = $"main/PluginLevel Button"

var current_layer: Node


func _ready():
	var getmaxfps = settings.get_setting("Video Settings", "Frameratelimit")
	var getfullscreen = settings.get_setting("Video Settings", "Fullscreen")
	var getvsync = settings.get_setting("Video Settings", "EnableV-Sync")
	Engine.set_target_fps(getmaxfps)
	OS.set_window_fullscreen(getfullscreen)
	OS.set_use_vsync(getvsync)
	current_layer = main
	for menu in get_children():
		menu.hide()
	$background.show()
	main.show()
	var getsens = settings.get_setting("Mouse", "Sensitivity")
	sens.text = str(getsens)
	$"Settings/Sensitivity Container/Sensitivity Slider".set_value(getsens)
	$"Video Settings/Max FPS container/Max FPS".set_text(str(getmaxfps))
	$"Video Settings/Fullscreen".set_pressed(getfullscreen)
	$"Video Settings/Enable VSync".set_pressed(getvsync)

func _input(event):
	if (Input.is_action_just_pressed("ui_cancel")):
		match current_layer:
			settings_menu:
				_go_to_layer(main)
				settings.save_settings()
			crosshair_menu:
				_go_to_layer(settings_menu)
			video_settings_menu:
				_go_to_layer(settings_menu)


func _go_to_layer(to: Node):
	current_layer.hide()
	to.show()
	current_layer = to


func _on_Settings_Button_pressed():
	_go_to_layer(settings_menu)


func _on_Exit_button_pressed():
	settings.save_settings()
	get_tree().quit()


func _on_Devlevel_Button_pressed():
	get_tree().change_scene("res://DevLevel.tscn")


func _on_Crosshair_Settings_Button_pressed():
	_go_to_layer(crosshair_menu)

func _on_sensitivity_value_changed(value):
	sens.text = str(value)
	settings.change_setting("Mouse", "Sensitivity", value)


func _on_PluginLevel_Button_pressed():
	get_tree().change_scene("res://testing folder/player plugin test.tscn")

func _on_Testing_Button_pressed():
	get_tree().change_scene("res://testing folder/test.tscn")


func _on_fullscreen_toggled(button_pressed):
	OS.set_window_fullscreen(button_pressed)
	settings.change_setting("Video Settings", "Fullscreen", button_pressed)


func _on_Video_Settings_Button_pressed():
	_go_to_layer(video_settings_menu)


func _on_Enable_VSync_toggled(button_pressed):
	OS.set_use_vsync(button_pressed)
	settings.change_setting("Video Settings", "EnableV-Sync", button_pressed)


func _on_Max_FPS_text_changed(new_text):
	var maxfps = int(new_text)
	Engine.set_target_fps(maxfps)
	settings.change_setting("Video Settings", "Frameratelimit", maxfps)
