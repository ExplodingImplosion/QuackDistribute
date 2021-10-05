extends Timer
class_name Gamemode

onready var gametimer: Timer

onready var roundtimer: Timer

export var gamemode_name: String = "Default gamemode"

export(int, 0, 216000) var game_time_limit: int = 300

export(int, 0, 108000) var round_time_limit: int = 300

export var breaks_between_rounds: bool = false

export(int, 0, 120) var between_rounds_time_limit: int = 10

export var downtime_before_round: bool = false

export(int, 0, 60) var downtime_limit_before_round: int = 10

enum {LOBBYFULL, TEAMSFULL, INSTANTLY, MANUAL}
export(int, "Lobby Full", "Teams Full", "Instantly", "Manual") var start_game_condition: int = 0

export(int, 0, 300) var start_idle_time: int = 10

export var cancel_start_if_conditions_changed: bool = false

export(int, 1, 100) var rounds: int = 1

export(bool) var tiebreaker_round: bool = false

export(int, 1, 10) var tiebreaker_round_count: int = 0

#defines what kind of teams the mode uses. 0 = FFA, 1 = co-op, 2 = 2 teams, and so on
enum {FFA, COOP, TWOTEAMS, THREETEAMS}
export(int, 0, 20) var team_type: int = 0

export(bool) var auto_sort_teams: bool = false

export(int, "Always", "At start of match", "Between rounds", "No") var allow_team_switching: int = 0

#defines whether or not the game should be respawning players mid-round by default
export(bool) var respawns: bool = true

export(int, 0, 60) var respawn_time: int = 5

#defines if players can manually override the respawn timer to respawn on a shorter timer
export(bool) var manual_respawn_override: bool = true

# 
export(float) var manual_respawn_time: float = 0.0

export(float) var synchronized_spawns: bool = false

export(int, 1, 20) var player_limit: int = 10

export(int, 0, 20) var spectator_limit: int = 2

export(String, "None", "Base Weapon", "Map Override", "M4", "AK", "1911", "Glock") var player_gun_1: String = "M4"
export(String, "None", "Base Weapon", "Map Override", "M4", "AK", "1911", "Glock") var player_gun_2: String = "1911"

export(float, 0, 100) var max_speed: float = 40.0
export(float, 0, 58.8) var gravity: float = 29.4
export(float, 0, 30) var max_floor_speed: float = 10.0
export(float, 0, 10) var acceleration: float = 4.0
export(float, 0, 15) var decceleration: float = 8.0
export(float, 0, 1) var air_acceleration: float = 0.25
export(float, 0, 1) var air_decceleration: float = 0.0125
export(float, 0, 50) var jump_strength: float = 10.0
export(float, 0, 1) var crouch_factor: float = 0.3
export(float, 0, 2) var walk_factor: float = 0.5
export(int, 1, 100000) var max_player_hp: int = 100

export var gamemode_environment_override: Environment = null

var params: Dictionary

# maybe this should be a server variable
#var is_between_rounds: bool = false
#var is_before_round: bool = false

signal on_game_started
signal game_timer_timeout

signal on_round_started
signal round_timer_timeout

signal on_game_paused
signal on_round_paused

signal round_break_started
signal round_break_ended

signal round_downtime_started
signal round_downtime_ended

# what was previously in _ready() is now in the on_tree_entered() func
func _ready():
	on_tree_entered()

#unfinished function that's supposed to be manually altered for individual modes
func _on_score_changed(event):
	# should create some kind of event using data that fires off from the network
	# script, since the network script is what handles events, etc
	pass

func _on_game_timer_timeout():
	emit_signal("game_timer_timeout")

func _init(override: Dictionary = {}):
	if override.size() > 0:
		for key in override.keys():
			params[key] = override[key]
	else:
		params = export_gamemode()

func export_gamemode() -> Dictionary:
	return {
		"gamemode_name": gamemode_name,
		"game_time_limit": game_time_limit,
		"round_time_limit": round_time_limit,
		"rounds": rounds,
		"breaks_between_rounds": breaks_between_rounds,
		"between_rounds_time_limit": between_rounds_time_limit,
		"downtime_before_round": downtime_before_round,
		"downtime_limit_before_round": downtime_limit_before_round,
		"tiebreaker_round": tiebreaker_round,
		"tiebreaker_round_count": tiebreaker_round_count,
		"team_type": team_type,
		"auto_sort_teams": auto_sort_teams,
		"allow_team_switching": allow_team_switching,
		"respawns": respawns,
		"respawn_time": respawn_time,
		"manual_respawn_override": manual_respawn_override,
		"manual_respawn_time": manual_respawn_time,
		"player_limit": player_limit,
		"spectator_limit": spectator_limit,
		"player_gun_1": player_gun_1,
		"player_gun_2": player_gun_2,
		"max_speed": max_speed,
		"gravity": gravity,
		"acceleration": acceleration,
		"decceleration": decceleration,
		"air_acceleration": air_acceleration,
		"air_decceleration": air_decceleration,
		"jump_strength": jump_strength,
		"crouch_factor": crouch_factor,
		"walk_factor": walk_factor,
		"max_player_hp": max_player_hp,
		"gamemode_environment_override": gamemode_environment_override,
		"start_game_condition": start_game_condition,
		"start_idle_time": start_idle_time,
		"cancel_start_if_conditions_changed": cancel_start_if_conditions_changed,
		"synchronized_spawns": synchronized_spawns,
	}

func on_tree_entered():
	if OS.is_debug_build():
		set_name("Game Timer")
	# note about gametimer and stuff like that. realistically, the vars gametimer
	# and roundtimer dont need to exist lol. theyre really just here to make
	# reading the code and comprehending it easier
	gametimer = self
	if params.game_time_limit == 0:
		pass
	else:
		gametimer.set_wait_time(params.game_time_limit)
	if params.rounds > 1:
		# what with how this works now, if you were to use the packedscene version
		# of a gamemode as an actual gamemode at runtime, there would be a redundant
		# roundtimer. but since youre NOT SUPPOSED TO, and hopefully no one will,
		# just gonna make a new Timer and set its params the way they need to be
		roundtimer = Timer.new()
		roundtimer.set_one_shot(true)
#		if !roundtimer.is_inside_tree():
		add_child(roundtimer)
		if OS.is_debug_build():
			roundtimer.set_name("Round Timer")
		if params.downtime_before_round == true:
			roundtimer.set_wait_time(params.downtime_limit_before_round)
		else:
			roundtimer.set_wait_time(params.round_time_limit)

# these functions are named poorly. too bad!
func start_game() -> void:
	start_tha_game()
	if params.rounds > 1:
		if params.downtime_before_round == true:
			start_round_downtime()
		else:
			start_round()

func start_tha_game() -> void:
	gametimer.start()
	emit_signal("on_game_started")

func start_round_downtime() -> void:
	roundtimer.set_wait_time(params.downtime_before_round)
	roundtimer.connect("timeout", self, "on_round_downtime_ended", [], CONNECT_ONESHOT)
	roundtimer.start()
	emit_signal("round_downtime_started")

func on_round_downtime_ended() -> void:
	emit_signal("round_downtime_ended")
#	start_round()

func start_round_break() -> void:
	roundtimer.set_wait_time(params.between_rounds_time_limit)
	roundtimer.connect("timeout", self, "on_round_break_ended", [], CONNECT_ONESHOT)
	roundtimer.start()
	emit_signal("round_break_started")

func on_round_break_ended() -> void:
	emit_signal("round_break_ended")
#	start_round_downtime()

func start_round() -> void:
	roundtimer.set_wait_time(params.round_time_limit)
	roundtimer.connect("timeout", self, "on_round_ended", [], CONNECT_ONESHOT)
	roundtimer.start()
	emit_signal("on_round_started")

func on_round_ended() -> void:
	emit_signal("round_timer_timeout")
#	start_round_break()

func pause_game() -> void:
	gametimer.set_paused(true)
	if params.rounds > 1:
		pause_round()
	emit_signal("on_game_paused")

func pause_round() -> void:
	roundtimer.set_paused(true)
	emit_signal("on_round_paused")

# depreciated old functions that im leaving in because im mad that i had to delete
# it all

#func set_params(override: Dictionary):
#	gamemode_name = check_set_param("gamemode_name", override)
#	game_time_limit = check_set_param("game_time_limit", override)
#	round_time_limit = check_set_param("", override)
#	rounds = check_set_param("rounds", override)
#	tiebreaker_round = check_set_param("tiebreaker_round", override)
#	tiebreaker_round_count = check_set_param("tiebreaker_round_count", override)
#	team_type = check_set_param("team_type", override)
#	respawns = check_set_param("respawns", override)
#	respawn_time = check_set_param("respawn_time", override)
#	manual_respawn_override = check_set_param("manual_respawn_override", override)
#	manual_respawn_time = check_set_param("manual_respawn_time", override)
#	player_limit = check_set_param("player_limit", override)
#	spectator_limit = check_set_param("spectator_limit", override)
#	player_gun_1 = check_set_param("player_gun_1", override)
#	player_gun_2 = check_set_param("player_gun_2", override)
#	max_speed = check_set_param("max_speed", override)
#	gravity = check_set_param("gravity", override)
#	acceleration = check_set_param("acceleration", override)
#	decceleration = check_set_param("decceleration", override)
#	air_acceleration = check_set_param("air_acceleration", override)
#	air_decceleration = check_set_param("air_decceleration", override)
#	jump_strength = check_set_param("jump_strength", override)
#	crouch_factor = check_set_param("crouch_factor", override)
#	walk_factor = check_set_param("walk_factor", override)
#	max_player_hp = check_set_param("max_player_hp", override)


#func check_set_param(param_name: String, all_params: Dictionary):
#	if all_params.has(param_name):
#		print(all_params.param_name)
#		return all_params[param_name]
#	else:
#		return params[param_name]
