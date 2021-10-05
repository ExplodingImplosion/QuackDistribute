extends Control
class_name PlayerHUD

onready var health_readout: Label = $"Health Container/Health Readout"
onready var ammo_readout: Label = $"Ammo Container/Ammo Readout"
onready var score_1_readout: Label = $"Game Info Container/Score Container/Score 1"
onready var score_2_readout: Label = $"Game Info Container/Score Container/Score 2"
onready var fps_readout: Label = $"Debug Info/Info Container/FPS Container/FPS Readout"
onready var ping_readout: Label = $"Debug Info/Info Container/Ping Container/Ping Readout"
onready var chat: Container = $"Chat"
onready var killfeed: Container = $"Killfeed"
onready var crosshair: Control = $"Crosshair"
var console: WindowDialog = preloader.get_resource("Developer Console").instance()

func setup_console() -> void:
	add_child(console)
	console.hide()

func _ready() -> void:
	chat.chat_log_only()
	setup_console()
#	OS.set_window_fullscreen(true)

func update_full_hud(delta: float) -> void:
	set_fps_readout(Engine.get_frames_per_second())
	# set_ping_readout()

func set_int_readout(this_label: Label, this_value: int) -> void:
	this_label.set_text(String(this_value))

func set_health_readout(health: int) -> void:
	set_int_readout(health_readout, health)

func set_ammo_readout(ammo: int) -> void:
	set_int_readout(ammo_readout, ammo)

func set_score_1_readout(score: int) -> void:
	set_int_readout(score_1_readout, score)

func set_score_2_readout(score: int) -> void:
	set_int_readout(score_2_readout, score)

func set_fps_readout(FPS: int) -> void:
	set_int_readout(fps_readout, FPS)

func set_ping_readout(ping: float) -> void:
	# sets the ping readout text to a string version of the ping value passed
	# multiplied by 1000 to convert it into a ms unit
	ping_readout.set_text(str("%s ms"%[int(ping * 1000)]))

func set_ping_readout_ms(ping: int) -> void:
	# sets the ping readout to a string version of the ping value passed in integer
	# form, assuming that the ping value passed was in an ms unit
	ping_readout.set_text(str("%s ms"%[ping]))

func show_chat() -> void:
	chat.show()

func hide_chat() -> void:
	chat.hide()

func show_chat_full() -> void:
	chat.show_chat_full()

func show_chat_log_only() -> void:
	chat.chat_log_only()

func show_crosshair() -> void:
	crosshair.show()

func hide_crosshair() -> void:
	crosshair.hide()

func get_local_player_current_weapon() -> BaseWeapon:
	return Lobby.playerlist[Lobby.selfid].my_playercontroller.current_weapon

func update_ammo_count() -> void:
	set_ammo_readout(get_local_player_current_weapon().current_ammo)

func on_player_ADS() -> void:
	hide_crosshair()

func on_player_leave_ADS() -> void:
	show_crosshair()

func on_player_fired() -> void:
	update_ammo_count()

func on_player_reloaded() -> void:
	update_ammo_count()

func on_new_weapon_drawn() -> void:
	update_ammo_count()
