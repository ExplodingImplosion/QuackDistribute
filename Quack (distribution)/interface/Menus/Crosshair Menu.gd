extends Control

#was there ever a reason for this?
#onready var crosshairbutton = $options/Crosshair
onready var length = $LengthReadout
onready var width = $WidthReadout
onready var opacity = $OpacityReadout
onready var gap = $GapReadout
onready var bsize = $BorderSizeReadout
onready var bopacity = $BorderOpacityReadout
onready var dsize = $DotSizeReadout
onready var dopacity = $DotOpacityReadout
onready var crosshair_rep = $CrosshairReadout

func _ready():
#	$CenterContainer/crosshair/DotSettings/DotTrueFalse/TrueFalse.connect("toggled", self, "_on_dot_toggled")
	
	#SOMETHING WORTH NOTING: i could probably just pull these settings from the crosshair_rep's vars.
	# Just a thought.
	
	#grabbing general crosshair settings from the config file
	var getlength = settings.get_setting("Crosshair Settings", "Length")
	var getwidth = settings.get_setting("Crosshair Settings", "Width")
	var getopacity = settings.get_setting("Crosshair Settings", "Opacity")
	var getgap = settings.get_setting("Crosshair Settings", "Gap")
	var getcolor = settings.get_setting("Crosshair Settings", "Color")
	
	#grabbing border settings from the config file
	var getborder = settings.get_setting("Crosshair Settings", "Border")
	var getbsize = settings.get_setting("Crosshair Settings", "BorderSize")
	var getbopacity = settings.get_setting("Crosshair Settings", "BorderOpacity")
	
	#grabbing dot settings from config
	var getdot = settings.get_setting("Crosshair Settings", "Dot")
	var getdsize = settings.get_setting("Crosshair Settings", "DotSize")
	var getdopacity = settings.get_setting("Crosshair Settings", "DotOpacity")
	var getdborder = settings.get_setting("Crosshair Settings", "DotBorder")
	var getdcolor = settings.get_setting("Crosshair Settings", "DotColor")
	
	#setting general crosshair settings
	$CenterContainer/crosshair/MainSettings/Length/HSlider.set_value(getlength)
	$CenterContainer/crosshair/MainSettings/Width/HSlider.set_value(getwidth)
	$CenterContainer/crosshair/MainSettings/Opacity/HSlider.set_value(getopacity)
	$CenterContainer/crosshair/MainSettings/Gap/HSlider.set_value(getgap)
	$CrosshairColor/CrosshairColor.set_pick_color(getcolor)
	
	#setting border settings
	$CenterContainer/crosshair/BorderSettings/BorderTrueFalse/TrueFalse.set_toggle_mode(getborder)
	$CenterContainer/crosshair/BorderSettings/BorderSize/HSlider.set_value(getbsize)
	$CenterContainer/crosshair/BorderSettings/BorderOpacity/HSlider.set_value(getbopacity)
	
	#setting dot settings
	$CenterContainer/crosshair/DotSettings/DotTrueFalse/TrueFalse.set_toggle_mode(getdot)
	$CenterContainer/crosshair/DotSettings/DotSize/HSlider.set_value(getdsize)
	$CenterContainer/crosshair/DotSettings/DotOpacity/HSlider.set_value(getdopacity)
	$CenterContainer/crosshair/DotSettings/DotBorder/TrueFalse.set_toggle_mode(getdborder)
	$DotColor/DotColor.set_pick_color(getdcolor)
	
	crosshair_rep.set_position(OS.get_window_size()/4)


func _on_crosshair_length_changed(value):
	settings.change_setting("Crosshair Settings", "Length", value)
	length.text = str(value)
	crosshair_rep.rebuild_crosshair()


func _on_crosshair_width_changed(value):
	settings.change_setting("Crosshair Settings", "Width", value)
	width.text = str(value)
	crosshair_rep.rebuild_crosshair()


func _on_crosshair_opacity_changed(value):
	settings.change_setting("Crosshair Settings", "Opacity", value)
	opacity.text = str(value)
	crosshair_rep.rebuild_crosshair()


func _on_border_toggled(button_pressed):
	settings.change_setting("Crosshair Settings", "Border", button_pressed)
	crosshair_rep.rebuild_crosshair()


func _on_border_size_changed(value):
	settings.change_setting("Crosshair Settings", "BorderSize", value)
	bsize.text = str(value)
	crosshair_rep.rebuild_crosshair()


func _on_border_opacity_changed(value):
	settings.change_setting("Crosshair Settings", "BorderOpacity", value)
	bopacity.text = str(value)
	crosshair_rep.rebuild_crosshair()


func _on_dot_toggled(button_pressed):
	settings.change_setting("Crosshair Settings", "Dot", button_pressed)
	crosshair_rep.rebuild_crosshair()


func _on_dot_size_changed(value):
	settings.change_setting("Crosshair Settings", "DotSize", value)
	dsize.text = str(value)
	crosshair_rep.rebuild_crosshair()


func _on_dot_opacity_changed(value):
	settings.change_setting("Crosshair Settings", "DotOpacity", value)
	dopacity.text = str(value)
	crosshair_rep.rebuild_crosshair()


func _on_dot_border_toggled(button_pressed):
	settings.change_setting("Crosshair Settings", "DotBorder", button_pressed)
	crosshair_rep.rebuild_crosshair()


func _on_crosshair_color_changed(color):
	settings.change_setting("Crosshair Settings", "Color", color)
	crosshair_rep.rebuild_crosshair()


func _on_crosshair_dot_color_changed(color):
	settings.change_setting("Crosshair Settings", "DotColor", color)
	crosshair_rep.rebuild_crosshair()


func _on_gap_changed(value):
	settings.change_setting("Crosshair Settings", "Gap", value)
	gap.text = str(value)
	crosshair_rep.rebuild_crosshair()
