extends Menu

onready var settingsmenu = $"settings container"
onready var controls = $"controls settings container"
onready var gameplaysettings = $"gameplay settings container"
onready var videosettings = $"video settings container"
onready var sensreadout = $"controls settings container/Sensitivity Container/Readout"
onready var keybinds = $"keybinds container"
onready var audiosettings = $"Audio Settings"
onready var crosshairmenu = $"crosshair menu"

var exit_flag: bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	var getsens = settings.get_setting("Mouse", "Sensitivity")
	sensreadout.text = str(getsens)
	$"controls settings container/Sensitivity Container/Slider".set_value(getsens)

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		# there needs to be an exit flag, since if I try to check the current layer
		# from a pause menu or some kind of parent, it fucks itself since the current
		# layer gets changed back to settingsmenu before the parent's check happens
		if current_layer == settingsmenu:
			exit_flag = true
			settings.save_settings()
			return
		else:
			exit_flag = false
		match current_layer:
			gameplaysettings:
				_go_to_layer(settingsmenu)
			controls:
				_go_to_layer(settingsmenu)
			videosettings:
				_go_to_layer(settingsmenu)
			keybinds:
				_go_to_layer(controls)
			crosshairmenu:
				_go_to_layer(gameplaysettings)
			audiosettings:
				_go_to_layer(settingsmenu)

func _on_Gameplay_Settings_Button_pressed():
	_go_to_layer(gameplaysettings)


func _on_Controls_Settings_Button_pressed():
	_go_to_layer(controls)


func _on_Video_Settings_Button_pressed():
	_go_to_layer(videosettings)


func _on_Keybinds_Button_pressed():
	_go_to_layer(keybinds)


func _on_Behavior_Button_pressed():
	pass # Replace with function body.


func _on_Audio_Settings_pressed():
	_go_to_layer(audiosettings)

func _on_sensitivity_changed(value):
	sensreadout.text = str(value)
	settings.change_setting("Mouse", "Sensitivity", value)


func _on_Crosshair_Button_pressed():
	_go_to_layer(crosshairmenu)
