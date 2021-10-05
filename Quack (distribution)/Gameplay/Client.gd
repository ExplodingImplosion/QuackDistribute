extends NetworkPeer
class_name Client
var menu: Menu = preload("res://interface/Menus/Player Pause Menu.tscn").instance()
var HUD: PlayerHUD = preload("res://interface/HUDs/Player HUD.tscn").instance()


func _init(this_map: String, this_gamemode: Gamemode, this_player_limit: int, this_port: int):
	# add this server as a child of the scenetree
	Lobby.get_tree().get_root().add_child(self)
	
	setup_map(this_map)
	
	setup_vars(this_gamemode, this_player_limit, this_port, Replay.new([], Engine.iterations_per_second, 90))
	
	setup_connections()
	
	add_child(HUD)
	add_child(menu)
	if OS.is_debug_build():
		# this is really stupid but it needs to be done in order for godot to function properly
		set_name("Server")
		HUD.set_name("HUD")
		menu.set_name("Pause Menu")
	# originally the bit that ensures that the gamemode is inside the tree
	# was here, but I moved it to the Network Peer.gd's _ready() function
	# UPDATE: see Network Peer.gd's _init() func
	if !gamemode.is_inside_tree():
		add_child(gamemode)

func setup_vars(this_gamemode: Gamemode, this_player_limit: int, this_port: int, this_replay: Replay = Replay.new([], Engine.iterations_per_second, 90)):
	gamemode = this_gamemode
	player_limit = this_player_limit
	history = this_replay
	port = this_port

func setup_connections() -> void:
	connect("player_spawned", self, "spawn_player_client")
	

func disconnect_from_server():
	print("disconnecting from server...")
	print("disconnecting peers...")
	Lobby.peer.close_connection()
	print("saving replay...")
	# save replay
	print("resetting relevant vars")
	# reset relevant vars
	print("clearing Lobby player list")
	Lobby.clear_playerlist()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Lobby._begin_polling()
	get_tree().change_scene("res://interface/Menus/Multiplayer Menu.tscn")

func _physics_process(delta: float) -> void:
	send_packet()

func _process(delta: float) -> void:
	for player in entities.players:
		entities.players[player].tick(delta)
	update_hud(delta)

func update_hud(delta: float) -> void:
	HUD.update_full_hud(delta)

func on_game_entry_confirmed() -> void:
	pause_local_players()
	if can_change_team():
		menu.go_to_team_select_menu()
	else:
		menu.go_to_join_menu()
	set_physics_process(true)
	HUD.console.connect_node(self)
#	if gamemode.manual_respawn_override:
#		pass

func pause_local_players() -> void:
	for player in Lobby.local_players:
		player.pause()

func unpause_local_players() -> void:
	for player in Lobby.local_players:
		player.unpause()

func spawn_player_client(owner_id: int, start_transform: Transform, gun_1: BaseWeapon, gun_2: BaseWeapon, this_team: int) -> void:
	spawn_player(owner_id, start_transform, gun_1, gun_2, this_team)
	if is_local_id(owner_id):
		menu.leave_team_menu()
		menu.exit()

func on_player_joined_team(player: int, this_team: int) -> void:
	print("player %s joined team %s"%[player, this_team])
	Lobby.playerlist[player].set_team(this_team)
	# this is dumb as fuck
	if is_local_id(player):
		if Lobby.get_local_player().team == -1:
			Lobby.get_local_player().start_spectating()
			menu.exit()
			unpause_local_players()
		# if the player switches from one non-spectator team to another, the stop_spectating
		# func only takes one line to realize that the player wasnt spectating
		elif Lobby.get_local_player().is_connected("mouse_moved", Lobby.get_local_player(), "aim_spectator_camera"):
			Lobby.get_local_player().stop_spectating()

func setup_entities(info: Dictionary) -> void:
	print("setting up entities")
	for player in info.players:
		var this_player: Dictionary = info.players[player]
		print(this_player)
		spawn_player_client(player, this_player.transform, spawn_weapon(this_player.weapons[0].Name),
							spawn_weapon(this_player.weapons[1].Name), this_player.team)
		entities.players[player] = get_player(player).my_playercontroller
#var entities: Dictionary = {
#	"players": {},
#	"weapons": {},
#	"projectiles": {},
#}
#func verify_team_request(sender_id: int, team: int) -> void:
#	# this just makes things easier to understand in the context of this function
#	# allow_team_switching modes are as follows (not enumerated, since its an
#	# export var): always (0), at start of match (1), between rounds (2), and
#	# never (3)
#	var team_switching_allowed = gamemode.allow_team_switching
#	print("player %s attempted to change team to %s..."%[sender_id, team])
#	if team_switching_allowed >= 3:
#		print("gamemode dictates players are not allowed to switch teams!")
#		return
#	elif team_switching_allowed == 2:
#		if !is_mid_round:
#			try_add_player_to_team_by_idx(sender_id, team)
#		else:
#			print("gamemode dictates player cannot join a team during a round!")
#	elif team_switching_allowed == 1:
#		if !is_mid_game:
#			try_add_player_to_team_by_idx(sender_id, team)
#		else:
#			print("gamemode dictates that a player cannot join a team when the game is running!")
#	else:
#		try_add_player_to_team_by_idx(sender_id, team)

var ticks_recieved: Array
var most_recent_ticknum: int = 0

func update_most_recent_ticknum(this_ticknum: int) -> void:
	if this_ticknum > most_recent_ticknum:
		most_recent_ticknum = this_ticknum

remote func recieve_packet(info: Dictionary) -> void:
	for tick in info:
		if !is_redundant_tick(tick):
			for event in GameTick.get_events(info[tick]):
				print("event recieved in tick %s"%[tick])
				TickEvent.parse_event(event)
			ticks_recieved.append(int(tick))
			# this might add ticks in the wrong order but tbh im not so sure
			history.add_exported(info[tick])
			# if the above works fine then this might be redundant and stupid
			update_most_recent_ticknum(tick)
	sweep_ticks_recieved_for_deletion(info)
#	print(ticks_recieved)

func is_redundant_tick(this_tick: int) -> bool:
	if ticks_recieved.has(this_tick):
		return true
	else:
		return false

func flush_ticks_recieved() -> Array:
	var these_ticks: Array = ticks_recieved.duplicate()
	ticks_recieved.clear()
	print(these_ticks)
	return these_ticks

# maybe theres a faster way of doing this but hey fuck it
func sweep_ticks_recieved_for_deletion(info: Dictionary) -> void:
	for tick in ticks_recieved:
		if !info.has(tick):
			ticks_recieved.erase(tick)

func send_packet() -> void:
	var updates: Array
	for player in Lobby.local_players:
		updates.append(player.generate_update())
	rpc_unreliable_id(1, "recieve_player_packet", PlayerUpdatePacket.make_packet(ticks_recieved, updates))

# CONSOLE COMMANDS
# ------------------------------------------------------------------------------
# //////////////////////////////////////////////////////////////////////////////
# ------------------------------------------------------------------------------

func disconnect_cmd() -> void:
	disconnect_from_server()

func set_time_scale_cmd(new_scale: float) -> void:
	print("Time scale set to %s"%[new_scale])
	Engine.set_time_scale(new_scale)
