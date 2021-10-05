extends Node


onready var HoverSoundPlayer: AudioStreamPlayer = $"Hover Sound Player"
onready var PressSoundPlayer: AudioStreamPlayer = $"Press Sound Player"
onready var parent = get_parent()

#export var node_types_to_connect: PoolStringArray = ["Button", "HSlider", "CheckBox", "OptionButton"]


func _ready():
	connect_children(parent)


func connect_children(node: Node):
	var children: Array = node.get_children()
	if children.size() == 0:
		return
	else:
		for child in children:
			decide_connections_by_class(child)
			connect_children(child)

func decide_connections_by_class(node: Node):
	var this_class: String = node.get_class()
	match this_class:
		"Button":
			connect_button_signals(node)
		"HSlider":
			connect_slider_signals(node)
		"CheckBox":
			connect_button_signals(node)
		"OptionButton":
			connect_dropdown_signals(node)
		"CheckButton":
			connect_button_signals(node)

func connect_general_signals(node: Control):
	connect_if_not(node, ["mouse_entered", self, "play_hover_sound"])
	connect_if_not(node, ["focus_entered", self, "play_hover_sound"])
#	if !node.is_connected("mouse_entered", self, "play_hover_sound"):
#		node.connect("mouse_entered", self, "play_hover_sound", [])
#	if !node.is_connected("focus_entered", self, "play_hover_sound"):
#		node.connect("focus_entered", self, "play_hover_sound", [])

func connect_button_signals(button: Button):
	connect_general_signals(button)
	connect_if_not(button, ["pressed", self, "play_press_sound"])
#	if !button.is_connected("pressed", self, "play_press_sound"):
#		button.connect("pressed", self, "play_press_sound", [])

func connect_slider_signals(slider: Range):
	connect_general_signals(slider)
	connect_if_not(slider, ["value_changed", self, "play_slider_sound"])
#	if !slider.is_connected("value_changed", self, "play_slider_sound"):
#		slider.connect("value_changed", self, "play_slider_sound", [])

func play_slider_sound(_value: float):
	play_press_sound()

func play_item_sound(_value: int):
	play_press_sound()

func connect_dropdown_signals(dropdown: OptionButton):
	connect_general_signals(dropdown)
	connect_button_signals(dropdown)
	connect_if_not(dropdown, ["item_focused", self, "play_hover_sound"])
	connect_if_not(dropdown, ["item_selected", self, "play_item_sound"])
#	if !dropdown.is_connected("item_focused", self, "play_hover_sound"):
#		dropdown.connect("item_focused", self, "play_hover_sound", [])
#	if !dropdown.is_connected("item_selected", self, "play_item_sound"):
#		dropdown.connect("item_selected", self, "play_item_sound", [])

func play_press_sound():
	play_sound(PressSoundPlayer)

func play_hover_sound():
	play_sound(HoverSoundPlayer)

func play_sound(player: AudioStreamPlayer) -> void:
	if is_audio_on() == true:
		player.play(0.0)

func is_audio_on() -> bool:
	return settings.get_setting("Audio Settings", "MenuFeedback")

func connect_if_not(this: Control, these_params: Array) -> void:
	if !this.is_connected(these_params[0], these_params[1], these_params[2]):
		this.connect(these_params[0], these_params[1], these_params[2], [])
