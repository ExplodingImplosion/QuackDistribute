extends Spatial

onready var spawnpoints = []
onready var playerList = []
onready var playerScores = []
onready var preloader = $preloader

onready var rng = RandomNumberGenerator.new()

const maxsp = 40
const accel = 4

const grav = 9.8 * 3
const maxwsp = 16
const waccel = 8
const wdeccel = 8
const aaccel = 0.5
const adeccel = 0.5

const jump_strength = 10

const maxhp = 100

var delt = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	for child in self.get_children():
		if child.is_in_group("spawns"):
			spawnpoints.append(child)
	set_physics_process(false)

func _process(delta):
	pass

func get_respawn_position():
		if spawnpoints.size() > 0:
			return spawnpoints[int(rng.randf_range(0, spawnpoints.size() - 1))].global_transform.origin
		else:
			return(Vector3(0,0,0))

remotesync func pauseTimer():
	pass

remotesync func changePlayerScore(player, value):
	var playerValue = null
	var count = 0
	for child in playerList.size():
		if playerList[count] == player:
			playerValue = count
		else:
			count += 1
	if playerValue != null:
		playerScores[playerValue] += value
		print(str(player) + "s score went up by " + str(value))

func _on_gameTimer_timeout():
	var winner = null
	var winnerScore = null
	var tied = 2
	var tiedPlayers = []
	for score in playerScores:
		if winnerScore != null:
			if playerScores[score] > winnerScore:
				winnerScore = playerScores[score]
				winner = winnerScore[score]
		elif playerScores[score] > 0:
			winnerScore = playerScores[score]
			winner = winnerScore[score]
	

#func _physics_frame():
#	if get_tree().is_network_server():
#		_update_info(delt)
#		_server_send_info()
#		_update_history()

func _physics_process(delta):
	pass
