extends Node

# shortcut constants
const localhost = 'localhost'
const default_port := 25565
const default_browser_port := 42069
const default_local_browser_port := 25566
const miles_ip := '73.234.173.172'

# global browser and game lobby variables and settings
var browser := ServerBrowserDialogue.new()
var local_advertiser := ServerBrowserDialogue.new()
var peer: NetworkedMultiplayerENet
var selfid: int
var local_player_count: int = 1
var local_players: Array

# these vars might not be needed
var current_port: int
var current_browser_port: int
var current_local_browser_port: int

var my_client: NetworkPeer

# in-game vars
remote var playerlist: Dictionary
remote var playerIDlist: Array
remote var match_start_time: int
remote var player_limit: int

signal on_team_selected(player_id, team)

func _ready() -> void:
	add_child(browser.timer)
	add_child(local_advertiser.timer)
	if OS.is_debug_build():
		browser.timer.set_name("Browser Timer")
		local_advertiser.timer.set_name("Local Advertiser Timer")

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	pass

func _begin_polling(on_send_port:= browser.send_port, on_recieve_port:= browser.recieve_port, these_destinations:= browser.destination_ips):
	browser._begin_listening(on_recieve_port, these_destinations)
	browser._begin_pinging(on_send_port, these_destinations)
#	local_advertiser._begin_listening(on_recieve_port)

func _stop_polling():
	browser._stop_pinging()
	browser._stop_listening()
#	local_advertiser._stop_listening()

func connect_to_server(this_ip: String = localhost, this_port: int = default_port) -> void:
	if this_ip == '':
		this_ip = localhost
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(this_ip, this_port)
	get_tree().set_network_peer(peer)
	peer.set_target_peer(1)
	peer.connect("connection_succeeded", self, "on_connection_succeeded", [this_ip])
	peer.connect("connection_failed", self, "on_connection_failed", [this_ip])
	print("attempting to connect to host %s" % [this_ip])
	_stop_polling()

func on_connection_succeeded(to_ip: String) -> void:
	print("connection to %s succeeded!" % [to_ip])
	peer.connect("server_disconnected", self, "on_server_disconnected")

func on_connection_failed(to_ip: String) -> void:
	print("connection to %s failed." % [to_ip])
	_begin_polling()

func create_server(headless: bool, this_map: String, this_gamemode: Gamemode, player_limit: int = 10, port: int = default_port, browser_port: int = default_browser_port, local_browser_port: int = default_local_browser_port, is_local: bool = true):
	peer = NetworkedMultiplayerENet.new()
	peer.set_server_relay_enabled(false)
	peer.create_server(port, player_limit)
	get_tree().set_network_peer(peer)
	peer.set_target_peer(0)
	peer.connect("peer_connected", self, "on_peer_connected")
	peer.connect("peer_disconnected", self, "on_peer_disconnected")
	my_client = Server.new(this_map, this_gamemode, player_limit, is_local, port, headless)
	
	match_start_time = OS.get_unix_time()
	_stop_polling()
	print("Is local: %s"%[is_local])
	if !is_local:
		browser._begin_advertising(false)
		if OS.is_debug_build():
			local_advertiser.timer.set_name("Local Advertiser Timer")
		local_advertiser._begin_advertising(true)
	else:
		browser._begin_advertising(true)
	print(get_tree().current_scene.get_name())

func on_peer_connected(id: int):
	print("client %s connected" %[id])
	rpc_id(id, "connect_local_client", my_client.current_map, my_client.gamemode.params, my_client.player_limit, my_client.port, match_start_time)

func on_peer_disconnected(id: int):
	print("client %s disconnected" %[id])
	# this check is here in case the player disconnects before the player has a
	# chance to get added to the playerlist... which IS possible
	if Lobby.playerlist.has(id):
		my_client.remove_player_from_their_team(id)
		playerlist[id].delete_playercontroller()
		remove_player_from_playerlist(id)

func on_server_disconnected():
	my_client.disconnect_from_server()

remote func _ping_server() -> void:
	pass

remote func connect_local_client(this_map: String, these_params: Dictionary, this_player_limit: int, this_port: int, this_start_time: int) -> void:
	var this_gamemode: Gamemode = Gamemode.new(these_params)
	selfid = get_tree().get_network_unique_id()
	my_client = Client.new(this_map, this_gamemode, this_player_limit, this_port)
	match_start_time = this_start_time
	# this next line of code calls the start_game function on the multiplayer menu
	get_tree().current_scene.start_game()
	rpc_id(1, "check_player_count", local_player_count)

remote func check_player_count(playercount: int):
	var id: int = get_tree().get_rpc_sender_id()
	if has_room(playercount):
		rpc_id(id, "add_local_players", playercount)
		rpc("add_new_remote_players", id, playercount)
		# ALTERNATE WAY THAT MIGHT BE WORTH EXPLORING: turn add_remote_player into
		# remote func, remove the playerIDlist and its related stuff, and then run
		# the code below
#		for player in playerlist.keys():
#			rpc_id(id, "add_remote_player", playerlist[player].get_network_master())
		rpc_id(id, "add_remaining_remote_players", playerIDlist)
		# stuff like the match start time could totally be "manually" set with
		# something like rset_id(id, "match_start_time", match_start_time)
		rpc_id(id, "catch_up_with_server", match_start_time, my_client.export_entities(), my_client.export_all_teams())
		my_client.on_peer_joined_game(playercount)
	else:
		peer.disconnect_peer(id)

remote func add_local_players(playercount: int) -> void:
	for player in playercount:
		add_player_to_playerlist(selfid, LocalPlayer.new(player - 1))

remote func add_remaining_remote_players(players: Array) -> void:
	for player in players:
		add_remote_player(player)

remotesync func add_new_remote_players(id: int, playercount: int) -> void:
	for player in playercount:
		add_remote_player(id)

func add_remote_player(id: int) -> void:
	if id == selfid:
		return
	add_player_to_playerlist(id, RemotePlayer.new(id))

# for clients to perform a catch-up with the server the first time they connect to the
# match
remote func catch_up_with_server(start_time: int, info: Dictionary, team_info: Array):
	match_start_time = start_time
	my_client.import_all_teams(team_info)
	my_client.setup_entities(info)
	for item in info:
		pass
	my_client.on_game_entry_confirmed()

func get_server_info() -> Array:
	return [my_client.current_map, my_client.gamemode.params.gamemode_name, my_client.player_limit, playerlist.size(), my_client.port]

func add_player_to_playerlist(id: int, player: PlayerInterface) -> void:
	add_child(player)
	player.set_network_master(id)
	playerlist[id] = player
	playerIDlist.append(id)
	# there might be a more efficient way of doing this
	if player is LocalPlayer:
		local_players.append(player)

remotesync func remove_player_from_playerlist(id: int) -> void:
	playerlist[id].queue_free()
	playerlist.erase(id)
	playerIDlist.erase(id)

func clear_playerlist() -> void:
	for key in playerlist.keys():
		# this has a chance that, if this gets fucked up and not all the keys
		# are ints, that this will crash the program
		remove_player_from_playerlist(key)
	clear_local_players()
	playerIDlist.clear()

func clear_local_players() -> void:
	for player in local_players:
		player.queue_free()
	local_players.clear()

func has_room(for_players: int) -> bool:
	if for_players + playerlist.size() <= my_client.player_limit:
		return true
	else:
		return false

func save_replay():
	if my_client.history:
		my_client.history.save()
	else:
		print("Failed to save replay. Replay has not been instanced.")

func hash_network_id(id: int) -> int:
	return hash(str(id))

func hash_secondary_player(network_id: int, idx: int) -> int:
	return hash(str("%s_%s"%[network_id, idx]))

remote func on_team_selected(team: int) -> void:
	emit_signal("on_team_selected", get_tree().get_rpc_sender_id(), team)

func get_local_player() -> LocalPlayer:
	return Lobby.playerlist[selfid]
