extends Node
class_name NetworkPeer
var gamemode: Gamemode
var map: Map
var mapload: Resource
var player_limit: int
var history: Replay
var port: int
var current_map: String
var teams: Array
enum {PLAYERS, WEAPONS, PROJECTILES}
var entities: Dictionary = {
	"players": {},
	"weapons": {},
	"projectiles": {},
}
var is_mid_round: bool = false
var is_mid_game: bool = false
var is_round_break: bool = false
var is_downtime: bool = false
# maybe the current round, and team scores should be kept in the replay class
# in order to consolidate where data is stored/networked. maybe dont even keep
# the is_mid_round/game/team data in here, and just keep it all in the HUD/UI,
# to further reduce footprint.
var current_round: int
var current_tick: GameTick
#var current_exported_tick: Dictionary
var events: Array

# this is worded a bit poorly, but the "player" here refers to a player's index
signal player_joined_team(player, team)
signal player_fired_weapon(player)
signal player_threw_grenade(player)
signal player_spawned(player, location, gun1, gun2, team)
signal player_killed(killer, victim, assisters, cause)
signal player_damaged(inflictor, victim)
signal sound_triggered(object)
signal tryplant(player)
signal plant(player)
signal trydefuse(player)
signal defuse(player)
signal reload(player)
signal score_updated(new_score, for_team)

# theres a problem with this, because the gamemode isnt initialized when this
# happens, and if I add arguments, then it fucks up the extension _init()'s...
#func _init():
#	if !gamemode.is_inside_tree():
#		add_child(gamemode)

func _ready() -> void:
	set_physics_process(false)

func _init() -> void:
	setup_shared_connections()

func setup_shared_connections() -> void:
	connect("player_joined_team", self, "on_player_joined_team")

# load the map, instance it, then add it as a child of the node
func setup_map(this_map: String):
	current_map = this_map
	mapload = load(str("res://Maps/%s/%s.tscn"%[this_map, this_map]))
	map = mapload.instance()
	add_child(map)

func assign_playercontroller(this_playercontroller: PlayerController, to_player: PlayerInterface):
	to_player.assign_playercontroller(this_playercontroller)

func setup_teams():
	if gamemode.params.team_type == 0:
		teams.append(team.new(self, player_limit, "FFA"))
	else:
		var players_per_team: int = player_limit / gamemode.params.team_type
		for each_team in gamemode.params.team_type:
			teams.append(team.new(self, players_per_team))

func try_add_player_to_team(this_player: int, this_team: team, called_stupidly: bool = true) -> bool:
	if this_team.add_player(this_player):
		print("Player %s added to team %s"%[this_player, this_team.team_name])
		if called_stupidly:
			emit_signal("player_joined_team", this_player, get_team_position(this_team))
		return true
	else:
		print("Player %s could not be added to team! team is full!"%[this_player])
		return false

# this is really stupid and honestly it should just be the try_add_player_to_team_by_idx
# function
func get_team_position(this_team: team) -> int:
	for each_team_idx in teams.size():
		if hash(teams[each_team_idx]) == hash(this_team):
			return each_team_idx
	# this shouldnt ever happen
	print("AYO WHAT THE FUCK AYO AYO AYO AYO CHECK get_team_position in Network Peer.gd cuz this shouldnt get returned")
	get_tree().quit()
	return -1

func try_add_player_to_team_by_idx(this_player: int, idx: int) -> void:
	print("Attempting to add player %s to team %s..."%[this_player, idx])
	if try_add_player_to_team(this_player, teams[idx], false):
		emit_signal("player_joined_team", this_player, idx)
#		return true
#	else:
#		return false

# this doesnt work unless its on the server, since only the server
# has access to every tick that's been there. so, uh, maybe move this to the
# server script lol
func current_ticknum() -> int:
	return history.size()

class team:
	enum {PLAYERLIST, MAXPLAYERS, TEAMNAME, TEAMSCORE}
	# see comment at top of script
	var player_list: Array = []
	var max_players: int
	var team_name: String
	var team_score: int
	func _init(parent: NetworkPeer, these_max_players: int, unique_name: String = '', initial_player_list: Array = [], initial_score: int = 0) -> void:
		# = self.player_limit/ self.teams.size()
		max_players = these_max_players
		if unique_name == '':
#			unique_name = String(parent.teams.size() - 1)
			unique_name = str("Team %s"%[parent.teams.size() + 1])
		team_name = unique_name
		if initial_player_list.size() > 0:
			player_list = initial_player_list
		team_score = initial_score
	
	func add_player(player: int) -> bool:
		if !is_full():
			player_list.append(player)
			return true
		else:
			return false
	
	func delete_player_by_idx(idx: int) -> void:
		player_list.remove(idx)
	
	func delete_player_by_id(id: int) -> void:
		player_list.erase(id)
	
	func export_team() -> Array:
		return [player_list, max_players, team_name, team_score]
	
	func is_full() -> bool:
		return (current_player_count() >= max_players)
	
	func current_player_count() -> int:
		return player_list.size()

enum {PLAYERLIST, MAXPLAYERS, TEAMNAME, TEAMSCORE}

func get_team_name(idx: int) -> String:
	if !teams[idx].team_name || teams[idx].team_name == '':
		return "Team %s"%[idx + 1]
		
	else:
		return teams[idx].team_name

func export_all_teams() -> Array:
	var all_teams: Array
	for team in teams:
		all_teams.append(team.export_team())
	return all_teams

func import_all_teams(these_teams: Array) -> void:
	for each_team in these_teams:
		teams.append(team.new(self, each_team[MAXPLAYERS], each_team[TEAMNAME], each_team[PLAYERLIST], each_team[TEAMSCORE]))

func spawn_player(owner_id: int, start_transform: Transform, gun_1: BaseWeapon, gun_2: BaseWeapon, this_team: int) -> void:
#	var playerinst: PlayerController = preloader.get_resource("Player Character").instance().create(owner_id, start_location, gun_1, gun_2, this_team)
	var playerinst: PlayerController = preloader.new_player().create(owner_id, start_transform, gun_1, gun_2, this_team)
	entities.players[owner_id] = playerinst
	get_player(owner_id).assign_playercontroller(playerinst)

func spawn_weapon(gun_name: String) -> BaseWeapon:
	var gun: BaseWeapon = preloader.new_gun(gun_name)
#	entities.weapons[gun_name] = gun
	return gun

func get_player(player: int) -> PlayerInterface:
	return Lobby.playerlist[player]

func spawn_dropped_weapon_by_string(weapon: String, start_ammo : int, start_cycled : bool, start_unloaded : bool, start_extra_ammo : int):
	var new_weapon: DroppedWeapon = preloader.get_resource(weapon).instance()

func can_change_team() -> bool:
	if gamemode.params.team_type > 1 && !gamemode.params.auto_sort_teams:
		if gamemode.params.allow_team_switching == 0:
			return true
		elif gamemode.params.allow_team_switching == 1:
			if is_mid_game:
				return false
			else:
				return true
		elif gamemode.params.allow_team_switching == 2:
			if is_mid_round:
				return false
			else:
				return true
		else:
			return false
	else:
		return false

func add_event(type: int, event_params: Array) -> void:
	events.append(TickEvent.make_event(type, event_params))

func flush_events_to_tick(this_tick: GameTick) -> GameTick:
	for event in events:
		this_tick.events.append(event)
	events.clear()
	return this_tick

func spawn_gamemode_primary() -> BaseWeapon:
	return spawn_weapon(gamemode.params.player_gun_1)

func spawn_gamemode_secondary() -> BaseWeapon:
	return spawn_weapon(gamemode.params.player_gun_2)

func is_local_id(this_id: int) -> bool:
	return true if this_id == Lobby.selfid else false
