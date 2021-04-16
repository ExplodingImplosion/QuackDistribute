extends Node


const SAVE_PATH = "res://userdata/config.cfg"

var _config = ConfigFile.new()

const _defaults = {
	"Mouse" : {
		"Sensitivity": 1,
		"Invertlook": false,
		"Confinecursortogamewindowinfullscreen": false
	},
	"Bindings": {
		"PrimaryFire": 'MOUSE1',
		"SecondaryFire": 'MOUSE2',
		
		"Forward": 'W',
		"Backward": 'S',
		"Left": 'A',
		"Right": 'D',
		
		"Jump": 'SPACEBAR',
		"Crouch": 'CTRL'
	},
	"Video Settings" : {
		"Fullscreen": true,
		"Borderless": true,
		#should implement way to autodetect resolution for the default mode. separate setting, maybe?
		#maybe resolutions shouldn't be directly set up as vector2's, rather another dictionary of compatible
		#resolutions, to make things easier in the future
		"Resolution": Vector2(1920,1080),
		"Frameratelimit": 300,
		"EnableV-Sync": false
	},
	#for some god damn reason the fuckin border opacity shows up twice in the config, once with no space
	#between border and opacity and one WITH a space. WTF? (in fact, this happens with all multi-word keys)
	"Crosshair Settings" : {
		"Color": Color(255,255,255,255),
		"Length": 5,
		"Width": 2,
		"Opacity": 255,
		"Border": true,
		"BorderSize": 1,
		"BorderOpacity": 255,
		"Gap": 1,
		"Dot": true,
		"DotColor": Color(0,255,0,255),
		"DotOpacity": 69,
		"DotSize": 1,
		"DotBorder": true
	}
}

func _ready():
	load_settings()

func _notification(notif):
	if notif == 1006:
		save_settings()

func change_setting(section, key, newvalue):
	_config.set_value(section, key, newvalue)

func get_setting(section, key):
	return _config.get_value(section, key)

func save_settings():
	var error = _config.save(SAVE_PATH)
	if error == OK:
		print("config file saved successfully at %s" % SAVE_PATH)
	else:
		print("failed to save config file at %s || filepath is probably obstructed. unluckers!" % SAVE_PATH)

func load_settings():
	var error = _config.load(SAVE_PATH)
	if error != OK:
		print("failed to obtain config file from " + str(SAVE_PATH) + " || File may be missing, or filepath is obstructed")
		reset_to_defaults()
	else:
		for section in _config.get_sections():
			for key in _config.get_section_keys(section):
				if _config.get_value(section, key, null) == null:
					_config.set_value(section, key, _defaults[section][key])

func reset_to_defaults():
	for section in _defaults.keys():
		for key in _defaults[section]:
			_config.set_value(section, key, _defaults[section][key])
	
	_config.save(SAVE_PATH)
