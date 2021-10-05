extends VBoxContainer

onready var mastervolume = $"Audio Settings Scroller/Audio Settings Container/Master Volume Container/Master Volume Readout"
onready var sfxvolume = $"Audio Settings Scroller/Audio Settings Container/SFX Volume/SFX Volume Readout"
onready var musicvolume = $"Audio Settings Scroller/Audio Settings Container/Music Volume/Music Readout"
onready var voiceinputlevel = $"Audio Settings Scroller/Audio Settings Container/Voice Input Container/Voice Input Readout"
onready var playervoicevolume = $"Audio Settings Scroller/Audio Settings Container/Player Voice Contianer/Player Voice Readout"

func _ready():
	var getmastervolume = settings.get_setting("Audio Settings", "MasterVolume")
	var getsfxvolume = settings.get_setting("Audio Settings", "SFXVolume")
	var getmusicvolume = settings.get_setting("Audio Settings", "MusicVolume") 
	var getvoiceinput = settings.get_setting("Audio Settings", "VoiceInputLevel")
	var getplayervoice = settings.get_setting("Audio Settings", "PlayerVoiceVolume")
	var getmenufeedback = settings.get_setting("Audio Settings", "MenuFeedback")
	AudioServer.set_bus_volume_db(0, linear2db(float(getmastervolume / 100.0)))
	$"Audio Settings Scroller/Audio Settings Container/Master Volume Container/Master Volume Slider".set_value(getmastervolume)
	$"Audio Settings Scroller/Audio Settings Container/SFX Volume/SFX Volume Slider".set_value(getsfxvolume)
	$"Audio Settings Scroller/Audio Settings Container/Music Volume/Music Slider".set_value(getmusicvolume)
	$"Audio Settings Scroller/Audio Settings Container/Voice Input Container/Voice Input Slider".set_value(getvoiceinput)
	$"Audio Settings Scroller/Audio Settings Container/Player Voice Contianer/Player Voice Slider".set_value(getplayervoice)
	$"Audio Settings Scroller/Audio Settings Container/Menu Feedback Checker".set_pressed(getmenufeedback)

func _on_Master_Volume_Slider_value_changed(value: int):
	# ADD CHANGE MASTER VOLUME HERE
	mastervolume.text = str(value)
	settings.change_setting("Audio Settings", "MasterVolume", value)
	AudioServer.set_bus_volume_db(0, linear2db(float(value / 100.0)))


func _on_SFX_Volume_Slider_value_changed(value: int):
	# ADD CHANGE SFX VOLUME HERE
	sfxvolume.text = str(value)
	settings.change_setting("Audio Settings", "SFXVolume", value)
#	AudioServer.set_bus_volume_db(0, linear2db(float(value / 100.0)))


func _on_Music_Slider_value_changed(value: int):
	# ADD CHANGE MUSIC VOLUME HERE
	musicvolume.text = str(value)
	settings.change_setting("Audio Settings", "MusicVolume", value)
#	AudioServer.set_bus_volume_db(0, linear2db(float(value / 100.0)))

func _on_Voice_Input_Slider_value_changed(value: int):
	# ADD CHANGE VOICE INPUT LEVEL HERE
	voiceinputlevel.text = str(value)
	settings.change_setting("Audio Settings", "VoiceInputLevel", value)
#	AudioServer.set_bus_volume_db(0, linear2db(float(value / 100.0)))


func _on_Player_Voice_Slider_value_changed(value: int):
	# ADD CHANGE PLAYER VOICE VOLUME HERE
	playervoicevolume.text = str(value)
	settings.change_setting("Audio Settings", "PlayerVoiceVolume", value)
#	AudioServer.set_bus_volume_db(0, linear2db(float(value / 100.0)))


func _on_Menu_Feedback_Checker_toggled(button_pressed: bool):
	settings.change_setting("Audio Settings", "MenuFeedback", button_pressed)
