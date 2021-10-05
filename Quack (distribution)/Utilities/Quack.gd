extends Node

onready var env_2D: Environment = get_tree().root.world.get_environment()

func _ready():
	apply_video_settings()

func apply_video_settings():
	Engine.set_target_fps(settings.get_setting("Video Settings", "Frameratelimit"))
	OS.set_window_fullscreen(settings.get_setting("Video Settings", "Fullscreen"))
	OS.set_use_vsync(settings.get_setting("Video Settings", "EnableV-Sync"))
	OS.set_window_size(settings.get_setting("Video Settings", "Resolution"))

func set_3D_enviroment(environment: Environment):
	get_tree().root.set_disable_3d(false)
	get_tree().root.world.set_environment(environment)


func set_2D_environment():
	get_tree().root.set_disable_3d(true)
	get_tree().root.world.set_environment(env_2D)

func go_to_3D_scene(scene: String, environment: Environment, reapply_video_settings: bool = false):
	set_3D_enviroment(environment)
	get_tree().change_scene(scene)
	if reapply_video_settings:
		apply_video_settings()

# changes the scenetree's scene to 
func leave_3D_scene(scene: String, reapply_video_settings: bool = false):
	set_2D_environment()
	get_tree().change_scene(scene)
	if reapply_video_settings:
		apply_video_settings()

func quit() -> void:
	settings.save_settings()
	get_tree().quit()
