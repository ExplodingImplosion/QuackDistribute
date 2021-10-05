extends VBoxContainer

onready var resolutions: Array = populate_resolutions()

func _ready():
	$"Fullscreen Checker".set_pressed(OS.is_window_fullscreen())
	$"Max FPS container/Max FPS".set_text(str(Engine.get_target_fps()))
	$"VSync Checker".set_pressed(OS.is_vsync_enabled())

func _on_Fullscreen_Checker_toggled(button_pressed):
	OS.set_window_fullscreen(button_pressed)
	settings.change_setting("Video Settings", "Fullscreen", button_pressed)


func _on_VSync_Checker_toggled(button_pressed):
	OS.set_use_vsync(button_pressed)
	settings.change_setting("Video Settings", "EnableV-Sync", button_pressed)


func _on_Max_FPS_text_changed(new_text):
	var maxfps = int(new_text)
	var maxfps_string = str(maxfps)
	if maxfps_string != new_text:
		$"Max FPS container/Max FPS".set_text(maxfps_string)
	Engine.set_target_fps(maxfps)
	settings.change_setting("Video Settings", "Frameratelimit", maxfps)

func _on_Resolution_dropdown_item_selected(index: int):
	# this got ditched in favor of hard-coding everything with a switch statement
	# so that way the drop-down menu gets pre-selected properly more efficiently
	# but then that got ditched and im glad i kept the code around because it helped
#	var res_drop = $"Resolution drop-down".get_text()
#	# this shit be hella lazy and the y val isnt actually the real y value but it
#	# only gets run once so fuck you!
#	var yval: String = res_drop.rsplit(" ", true, 1)[0]
#	var xval: String = yval.rsplit(" x ", true, 1)[0]
#	OS.set_window_size(Vector2(int(xval), int(yval.split(" x ")[1])))
	change_resolution(resolutions[index])

func change_resolution(res: Vector2 = OS.get_screen_size()):
	OS.set_window_size(res)
	settings.change_setting("Video Settings", "Resolution", res)

func populate_resolutions() -> Array:
	var resolutions: Array
	var res_drop:= $"Resolution drop-down"
	for item in res_drop.get_item_count():
		var text = res_drop.get_item_text(item).split(" ")
		resolutions.append(Vector2(int(text[0]), int(text[2])))
	# this is a cheat, where the initial drop-down is set by the same function
	# that populates the resolutions
	res_drop._select_int(resolutions.find(settings.get_setting("Video Settings", "Resolution")))
	return resolutions
