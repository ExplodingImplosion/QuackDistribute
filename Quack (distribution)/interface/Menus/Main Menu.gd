extends Menu

# sets up quick references to buttons and such
onready var main = $main
onready var play_button = $"main/Play Container/Play Button"
onready var settings_button = $"main/Settings Button"
onready var settings_menu = $Settings
onready var crosshair_menu = $CrosshairItems
onready var video_settings_menu = $"Video Settings"
onready var sens = $"Settings/Sensitivity Container/Sensitivity Readout"
onready var audio_menu = $"Audio Settings"
onready var usernamecontainer = $"Username Container"

func _ready():
	var getusername: String = settings.get_setting("Account Settings", "Username")
	var getsens = settings.get_setting("Mouse", "Sensitivity")
	sens.text = str(getsens)
	$"Settings/Sensitivity Container/Sensitivity Slider".set_value(getsens)
	$"Video Settings/Max FPS container/Max FPS".set_text(str(settings.get_setting("Video Settings", "Frameratelimit")))
	$"Video Settings/Fullscreen Checker".set_pressed(settings.get_setting("Video Settings", "Fullscreen"))
	$"Video Settings/VSync Checker".set_pressed(settings.get_setting("Video Settings", "EnableV-Sync"))
	if getusername == "":
		getusername = OS.get_environment("USERNAME")
	$"Username Container/Username Setter".set_text(getusername)
#	var v31 = Vector3(0,0.5,1.32)
#	var v32 = Vector3(43, 0.24, 2.64)
#	print(lerp(v31, v32, 0.5))
#	print(RemotePlayer.interpolate_vector3(v31, v32, 0.5))
#	get_tree().root.set_disable_3d(true)
#	get_tree().root.world.set_environment(load("res://testing folder/headless_environment.tres"))

func _input(event):
	if (Input.is_action_just_pressed("ui_cancel")):
		match current_layer:
			settings_menu:
				go_to_main()
				settings.save_settings()
			crosshair_menu:
				_go_to_layer(settings_menu)
			video_settings_menu:
				_go_to_layer(settings_menu)
			audio_menu:
				_go_to_layer(settings_menu)


func _on_Settings_Button_pressed():
	leave_main(settings_menu)


func _on_Exit_button_pressed():
	Quack.quit()


func _on_Crosshair_Settings_Button_pressed():
	_go_to_layer(crosshair_menu)

func _on_sensitivity_value_changed(value):
	sens.text = str(value)
	settings.change_setting("Mouse", "Sensitivity", value)

func _on_Testing_Button_pressed():
	get_tree().change_scene("res://testing folder/test.tscn")


func _on_Video_Settings_Button_pressed():
	_go_to_layer(video_settings_menu)


func _on_Audio_Settings_Button_pressed():
	_go_to_layer(audio_menu)


func _on_Play_Button_pressed():
	get_tree().change_scene("res://interface/Menus/Multiplayer Menu.tscn")

func go_to_main():
	_go_to_layer(main)
	usernamecontainer.show()

func leave_main(to: Node):
	_go_to_layer(to)
	usernamecontainer.hide()


func _on_Username_Setter_text_changed(new_text: String):
	settings.change_setting("Account Settings", "Username", new_text)
