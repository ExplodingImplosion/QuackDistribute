extends Timer
class_name Gamemode

#reference definer for the timer node
onready var gametimer = $"Game Timer"

#gamemode variables
export var gamemode_name: String = "Default gamemode"

#how long each round is
export(int, 0, 216000) var time_limit = 300

#number of rounds before the game ends
export(int, 1, 100) var rounds = 1

#defines what kind of teams the mode uses. 0 = FFA, 1 = co-op, 2 = 2 teams, and so on
export(int, 0, 20) var team_type = 0

#defines whether or not the game should be respawning players mid-round by default
export(bool) var respawns = true

#defines how long dead players have to wait before respawning (if enabled)
export(int, 0, 60) var respawn_time = 5

#defines if players can manually override the respawn timer to respawn instantly
export(bool) var manual_respawn_override = true

#defines the maximum size of the game lobby (in players)
export(int, 1, 20) var player_limit = 10

#defines how many spectators can watch the game at once
export(int, 0, 20) var spectator_limit = 2

export(String, "Base Weapon", "M4", "AK", "1911") var player_gun_1: String = "M4"
export(String, "Base Weapon", "M4", "AK", "1911") var player_gun_2: String = "1911"

#sets stuff correctly blah blah blah
func _ready():
	if time_limit == 0:
		pass
	else:
		gametimer.set_wait_time(time_limit)

#unfinished function that's supposed to be manually altered for individual modes
func _on_score_changed(event):
	#should create some kind of event using data that fires off from the network script, since the network
	# script is what handles events, etc
	pass

func _on_round_ended():
	pass

func _on_timer_timeout():
	pass
