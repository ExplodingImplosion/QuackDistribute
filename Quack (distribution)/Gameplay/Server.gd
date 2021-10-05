extends NetworkPeer
class_name Server
var menu = preload("res://interface/Menus/Server Menu.tscn").instance()
var is_local: bool
var is_headless: bool
var this_environment: Environment
var all_spawns: Array
var team_1_spawns: Array
var team_2_spawns: Array
var FFA_spawn_idx: int
var team1_spawn_idx: int
var team2_spawn_idx: int
var respawn_queue: Array


func _init(this_map: String, this_gamemode: Gamemode, this_player_limit: int, localornah: bool, this_port: int, headless: bool):
	# add this server as a child of the scenetree
	
	print("server init")
	Lobby.get_tree().get_root().add_child(self)
	
	setup_map(this_map)
	
	setup_vars(this_gamemode, this_player_limit, localornah, this_port, headless, Replay.new([], Engine.iterations_per_second, 90))
	
	setup_spawns()
	
	setup_teams()
	
	setup_connections()
	
	setup_server_window()
	
	print("adding menu")
	add_menu()
	if OS.is_debug_build():
		set_name("Server")
		if is_headless:
			Quack.set_3D_enviroment(load("res://testing folder/headless_environment.tres"))
			get_tree().root.set_disable_3d(true)
			menu.get_child(0).set_frame_color(Color("21667c"))
	elif !is_headless:
		Quack.set_3D_enviroment(this_environment)
	else:
		menu.get_child(0).set_frame_color(Color("21667c"))
	# originally the bit that ensures that the gamemode is inside the tree
	# was here, but I moved it to the Network Peer.gd's _ready() function
	# UPDATE: see Network Peer.gd's _init() func
	if !gamemode.is_inside_tree():
		add_child(gamemode)
	
	if gamemode.params.start_game_condition == Gamemode.INSTANTLY:
		start_game()

func _ready() -> void:
	menu.console.connect_node(self)
	set_physics_process(true)

func add_menu() -> void:
	add_child(menu)
	if is_headless:
		menu.show()

func setup_vars(this_gamemode: Gamemode, this_player_limit: int, localornah: bool, this_port: int, headless: bool, this_replay: Replay = Replay.new([], Engine.iterations_per_second, 90)):
	gamemode = this_gamemode
	player_limit = this_player_limit
	history = this_replay
	is_local = localornah
	port = this_port
	is_headless = headless
	if this_gamemode.params.gamemode_environment_override:
		this_environment = this_gamemode.params.gamemode_environment_override
	else:
		if map.map_environment:
			this_environment = map.map_environment
		else:
			this_environment = preloader.get_resource("Default 3D Environment")

func setup_connections() -> void:
	# this might get confusing lol
	gamemode.connect("on_game_started", self, "on_game_started")
	gamemode.connect("on_round_started", self, "on_round_started")
	
	gamemode.connect("game_timer_timeout", self, "on_game_timer_timeout")
	gamemode.connect("on_round_timer_timeout", self, "on_round_timer_timeout")
	
	Lobby.connect("on_team_selected", self, "verify_team_request")
	
	gamemode.connect("on_game_paused", self, "on_game_paused")
	gamemode.connect("on_round_paused", self, "on_round_paused")
	
	gamemode.connect("round_downtime_started", self, "on_round_downtime_started")
	gamemode.connect("round_downtime_ended", self, "on_round_downtime_ended")
	
	gamemode.connect("round_break_started", self, "round_break_started")
	gamemode.connect("round_break_ended", self, "round_break_ended")
	
	match gamemode.params.start_game_condition:
		Gamemode.LOBBYFULL:
			connect("player_joined_team", self, "start_if_lobby_full")
		Gamemode.TEAMSFULL:
			connect("player_joined_team", self, "start_if_teams_full")

func setup_server_window() -> void:
	OS.set_window_fullscreen(false)
	var server_resolution := Vector2(1200, 675)
	if OS.get_window_size() > server_resolution:
		OS.set_window_size(server_resolution)
	Engine.set_target_fps(Engine.iterations_per_second)
	if OS.is_debug_build():
		OS.set_window_title("Quack (SERVER) (DEBUG)")
	else:
		OS.set_window_title("Quack (SERVER)")

func shutdown() -> void:
	print("shutting down server...")
	# doing this first in order to make the save() function's logic work problem,
	# because as soon as the connection gets closed, the game is no longer a "server"
	# in the engine's eyes.
	print("saving replay...")
	history.save()
	print("disconnecting peers...")
	Lobby.peer.close_connection()
	# idk why im freeing the map from memory here if the server is supposed to be
	# fucking deleted lmfao
#	print("freeing map from memory...")
#	map.queue_free()
	print("resetting relevant vars")
	# reset relevant vars
	print("clearing Lobby player list")
	Lobby.clear_playerlist()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Lobby.browser._stop_advertising()
	if Lobby.local_advertiser:
		Lobby.local_advertiser._stop_advertising()
	get_tree().change_scene("res://interface/Menus/Multiplayer Menu.tscn")
	if OS.is_debug_build():
		OS.set_window_title("Quack (DEBUG)")
	else:
		OS.set_window_title("Quack")

func available_player_count() -> int:
	return player_limit - Lobby.playerlist.size()

func has_room(for_player_count: int = 1) -> bool:
	if available_player_count() >= for_player_count:
		return true
	else:
		return false

func setup_spawns():
	all_spawns = map.find_all_spawns()
	team_1_spawns = map.find_team_spawns(1)
	team_2_spawns = map.find_team_spawns(2)
	create_default_spawns_if_map_has_none()
	if gamemode.params.team_type == 0:
		all_spawns.shuffle()

func create_default_spawns_if_map_has_none() -> void:
	if all_spawns.empty():
		all_spawns.append(Position3D.new())
		map.add_child(all_spawns[0])
	if team_1_spawns.empty():
		team_1_spawns.append(all_spawns[0])
	if team_2_spawns.empty():
		team_2_spawns.append(all_spawns[0])

func _physics_process(delta: float) -> void:
	tick(delta)

func tick(delta: float) -> void:
	poll_for_respawns(delta)
	
# all of this shit happens in the remote_player physics process!
# -----------------------------------------------------------------------------
	# this could be done thru entities dict, which would probably be better/more
	# consistent, but fuck u im doing it thru the playerlist
#	for player in Lobby.playerlist:
#		get_player(player).server_tick_player(delta)
	current_tick = make_authoritative_tick()
	if current_tick.events.size() > 0:
		print("THIS TICK HAS EVENTS!")
	history.add(current_tick)
	send_players_packets()

func send_players_packets() -> void:
	for player in Lobby.playerlist:
		send_packet_to_player(player, generate_packet(player))

func send_packet_to_player(to_player: int, packet: Dictionary) -> void:
	rpc_unreliable_id(to_player, "recieve_packet", packet)
	defer_disconnect_player_if_afk_too_long(to_player, 10)
#	print("%s is currently missing %s packets"%[to_player, get_player(to_player).ticks_not_recieved.size()])
	get_player(to_player).ticks_not_recieved.append(current_ticknum())
#	get_player(to_player).updates_not_recieved.append(current_ticknum())

func defer_disconnect_player_if_afk_too_long(player_id: int, time_in_seconds: int):
	if get_player(player_id).ticks_not_recieved.size() >= Engine.iterations_per_second * time_in_seconds:
		call_deferred("disconnect_player", player_id)

func rpc_sender_id() -> int:
	return get_tree().get_rpc_sender_id()

enum {TICKSRECIEVED, UPDATES}
enum {DEVICEID, INPUTS, AIMANGLE, INFO}
remote func recieve_player_packet(player_info: Array) -> void:
	get_player(rpc_sender_id()).update_player(player_info[UPDATES][0][INPUTS], player_info[UPDATES][0][AIMANGLE], player_info[UPDATES][0][INFO])
#	print(get_player(rpc_sender_id()).ticks_not_recieved)
	verify_player_recieved_packets(player_info[TICKSRECIEVED])

func verify_player_recieved_packets(packets: Array) -> void:
	for each_tick in packets:
		get_player(rpc_sender_id()).ticks_not_recieved.erase(each_tick)

func make_authoritative_tick() -> GameTick:
	var this_tick: GameTick = GameTick.new(current_ticknum(), serialize_playerlist())
	return flush_events_to_tick(this_tick)

func generate_packet(for_player: int) -> Dictionary:
	var ticks: Array
	for tick in get_player(for_player).ticks_not_recieved:
		ticks.append(history.get_tick(tick))
	return GameplayPacket.create_packet(ticks)

func serialize_playerlist() -> Dictionary:
	var serialized_playerlist: Dictionary
	for player in Lobby.playerlist:
		# this reads really badly but basically what its doing is it adds an id
		# key to the serialized playerlist that's a key for the player's info
		if get_player(player).my_playercontroller:
			serialized_playerlist[get_player(player).my_playercontroller.owner_id] = get_player(player).my_playercontroller.generate_info()
	# another way of doing the above is:
#	for key in Lobby.playerlist.keys():
#		serialized_playerlist[key] = Lobby.playerlist[key].my_playercontroller
	return serialized_playerlist

# this might be worded poorly
func get_player(id: int) -> PlayerInterface:
	return Lobby.playerlist[id]

func start_game():
	gamemode.start_game()

# dont use these args its just how it gets set up with connections etc
func start_if_lobby_full(player: int, this_team: int) -> void:
	if Lobby.playerIDlist.size() == player_limit:
		start_game()

# dont use these args its just how it gets set up with connections etc
func start_if_teams_full(player: int, this_team: int) -> void:
	if teams_are_full():
		start_game()

func teams_are_full() -> bool:
	for each_team in teams:
		if !each_team.is_full():
			return false
	return true

# lol this didnt get used
func add_player_to_match(player: int):
	pass

# this function and the find team with least players function assume that there's
# room, somewhere, in the match for the players
func on_peer_joined_game(playercount: int) -> void:
	if gamemode.params.team_type > 1:
		if gamemode.params.auto_sort_teams == true:
			var top: int = Lobby.playerIDlist.size() 
			for each_player in playercount:
				try_add_player_to_team(Lobby.playerlist[top - each_player], find_team_with_least_players())

func find_team_with_least_players() -> team:
	var team_with_least_players: team = teams[0]
	for each_team in teams:
		if each_team.current_player_count() < team_with_least_players.current_player_count():
			team_with_least_players = each_team
	return team_with_least_players

# see on_peer_joined_game
func find_team_idx_with_least_players() -> int:
	var team_idx_with_least_players: int = 0
	for each_team in teams.size():
		if teams[each_team].current_player_count() < teams[team_idx_with_least_players].current_player_count():
			team_idx_with_least_players = each_team
	return team_idx_with_least_players

# GAME AND ROUND STARTING
func on_game_started() -> void:
	is_mid_game = true

func on_round_started() -> void:
	is_mid_round = true
	current_round += 1

# GAME AND ROUND PAUSING STUFF
func on_game_paused() -> void:
	is_mid_game = false

func on_round_paused() -> void:
	is_mid_round = false

# GAME AND ROUND TIMEOUTS
func on_game_timer_timeout() -> void:
	is_mid_game = false

func on_round_timer_timeout() -> void:
	is_mid_round = false

# DOWNTIME STUFF
func on_round_downtime_started() -> void:
	is_downtime = true

func on_round_downtime_ended() -> void:
	is_downtime = false

# ROUND BREAK STUFF
func round_break_started() -> void:
	is_round_break = true

func round_break_ended() -> void:
	is_round_break = false

func on_player_joined_team(player: int, this_team: int) -> void:
	remove_player_from_their_team(player)
	Lobby.playerlist[player].set_team(this_team)
	if this_team > -1:
		print("trying to spawn player")
		try_spawn_player_first_time(player)
	add_event(TickEvent.TEAMCHANGED, [player, this_team])

func add_player_to_respawn_queue(player: int, with_time: int = gamemode.params.respawn_time) -> void:
	if !respawn_queue_has_player(player):
		respawn_queue.append([player, with_time])
	else:
		print("player is already queued for respawn!")

func respawn_queue_has_player(player: int) -> bool:
	for players in respawn_queue:
		if players[PLAYER] == player:
			return true
	return false

func remove_player_from_respawn_queue(player: Array) -> void:
	respawn_queue.erase(player)

enum {PLAYER, TIMELEFT}
func poll_for_respawns(delta: float) -> void:
	for each_player in respawn_queue:
		each_player[TIMELEFT] -= delta
		if each_player[TIMELEFT] <= 0:
			if try_respawning_player(each_player[PLAYER]):
				remove_player_from_respawn_queue(each_player)

func try_spawn_player_first_time(player: int) -> void:
	if !get_player(player).my_playercontroller:
		add_player_to_respawn_queue(player, 0)

enum {FFA, COOP, TWOTEAMS, THREETEAMS}
func try_respawning_player(player: int) -> bool:
	if is_respawning_allowed():
		match gamemode.params.team_type:
			FFA:
				server_spawn_player(player, spawn_FFA(), spawn_gamemode_primary(), spawn_gamemode_secondary(), 0)
			COOP:
				pass
	#			spawn_player(player, spawn_COOP(), spawn_gamemode_primary(), spawn_gamemode_secondary(), 1)
			TWOTEAMS:
				pass
				server_spawn_player(player, spawn_TWOTEAMS(get_player(player).team), spawn_gamemode_primary(), spawn_gamemode_secondary(), get_player(player).team)
			THREETEAMS:
				pass
	#			spawn_player(player, spawn_THREETEAMS, spawn_gamemode_primary(), spawn_gamemode_secondary(), get_player(player).team)
			_:
				pass
		return true
	else:
		return false

func server_spawn_player(player_id: int, transform: Transform, gun1: BaseWeapon, gun2: BaseWeapon, team: int) -> void:
	spawn_player(player_id, transform, gun1, gun2, team)
#	menu.console.connect_node(entities.players[player_id])
	add_event(TickEvent.SPAWN, [player_id, transform, gun1.serialize(), gun2.serialize(), team])

func get_spawn(idx: int) -> Transform:
	return all_spawns[idx].get_global_transform()

func get_team_1_spawn(idx: int) -> Transform:
	return team_1_spawns[idx].get_global_transform()

func get_team_2_spawn(idx: int) -> Transform:
	return team_2_spawns[idx].get_global_transform()

func spawn_FFA() -> Transform:
	FFA_spawn_idx = clamp(FFA_spawn_idx + 1, 0, all_spawns.size() - 1)
	return get_spawn(FFA_spawn_idx)

func spawn_TWOTEAMS(team: int) -> Transform:
	if team == 0:
		team1_spawn_idx = clamp(team1_spawn_idx + 1, 0, team_1_spawns.size() - 1)
		return get_team_1_spawn(team1_spawn_idx)
	else:
		team2_spawn_idx = clamp(team2_spawn_idx + 1, 0, team_2_spawns.size() - 1)
		return get_team_1_spawn(team2_spawn_idx)

func is_respawning_allowed() -> bool:
	if !is_mid_game:
		return true
	if !gamemode.params.respawns:
		if is_mid_round || is_round_break:
			return false
		elif is_downtime:
			return true
		else:
			print("ayo what the fuck this shouldnt happen check Server.gd is_respawning_allowed")
			Quack.quit()
			return false
	else:
		return true

func remove_player(player: int) -> void:
	pass

func remove_player_from_team_by_team_idx(player: int, this_team: int) -> void:
	teams[this_team].delete_player_by_id(player)

func remove_player_from_their_team(player: int) -> void:
	print("removing player %s from their team"%[player])
	teams[Lobby.playerlist[player].team].delete_player_by_id(player)
	# WARNIGN: MIGHT WANT TO GET RIDF OF THIS
	get_player(player).delete_playercontroller()
	add_event(TickEvent.PLAYERREMOVED, [player])

func is_already_spectating(player: int) -> bool:
	if Lobby.playerlist[player].team == -1:
		return true
	else:
		return false

func verify_team_request(sender_id: int, team: int) -> void:
	# this could be integrated with the can_change_team stuff, but id rather have
	# these custom conditional prints
	
	# this just makes things easier to understand in the context of this function
	# allow_team_switching modes are as follows (not enumerated, since its an
	# export var): always (0), at start of match (1), between rounds (2), and
	# never (3)
	
	if team == -1:
		if is_already_spectating(sender_id):
			print("can't make a player a spectator if they're already spectating!")
			return
		else:
			print("moving player to spectator team")
			remove_player_from_their_team(sender_id)
			var this_player: RemotePlayer = get_player(sender_id)
			this_player.team = -1
#			this_player.my_playercontroller.queue_free()
#			this_player.my_playercontroller = null
	print(team)
	if team_switching_worked(sender_id, team):
		if team == -2:
			try_add_player_to_team_by_idx(sender_id, find_team_idx_with_least_players())
		else:
			try_add_player_to_team_by_idx(sender_id, team)

func team_switching_worked(sender_id: int, team: int) -> bool:
	var team_switching_allowed = gamemode.params.allow_team_switching
	print("player %s attempted to change team to %s..."%[sender_id, team])
	if team_switching_allowed >= 3:
		print("gamemode dictates players are not allowed to switch teams!")
		return false
	elif team_switching_allowed == 2:
		if !is_mid_round:
			return true
		else:
			print("gamemode dictates player cannot join a team during a round!")
			return false
	elif team_switching_allowed == 1:
		if !is_mid_game:
			return true
		else:
			print("gamemode dictates that a player cannot join a team when the game is running!")
			return false
	else:
		return true

func disconnect_player(id: int) -> void:
	remove_player_from_their_team(id)
	Lobby.remove_player_from_playerlist(id)
	Lobby.peer.disconnect_peer(id)

func export_entities() -> Dictionary:
	var these_entities: Dictionary = {
	"players": {},
	"weapons": {},
	"projectiles": {},}
	# should be functionally equivalent to these_entities.players = serialize_entity_category(players)
	# generate_info() for a playercontroller is the same as serialize()
	for player in entities.players:
		these_entities.players[player] = entities.players[player].generate_info()
	for weapon in entities.weapons:
		these_entities.weapons[weapon] = entities.weapons[weapon].serialize()
	these_entities.projectiles = serialize_entity_category("projectiles")
	return these_entities

func serialize_entity_category(this_category: String) -> Dictionary:
	var category: Dictionary
	for this in entities[this_category]:
		category[this] = entities[this_category][this].serialize()
	return category

# CONSOLE COMMANDS
# ------------------------------------------------------------------------------
# //////////////////////////////////////////////////////////////////////////////
# ------------------------------------------------------------------------------
func shutdown_cmd() -> void:
	shutdown()

func disconnect_player_cmd(id: int) -> void:
	disconnect_player(id)

func change_player_team_cmd(id: int, team: int) -> void:
	verify_team_request(id, team)

func disconnect_all_players_cmd() -> void:
	for id in Lobby.playerlist.keys():
		Lobby.peer.disconnect_peer(id)
