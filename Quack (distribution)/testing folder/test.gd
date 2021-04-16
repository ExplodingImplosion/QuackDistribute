extends Node

enum {FORWARD, BACK, LEFT, RIGHT, JUMP, SHOOT, RELOAD, ADS, GUN1, GUN2, MELEE, CYCLEGRENADES, MELEEWEAPON, GRENADE, CROUCH, WALK, DROP, INTERACT}
enum {FIRE, THROWGRENADE, SPAWN, KILL, DAMAGE, MAKESOUND}

remote var playerlist: Dictionary
remote var player_pings: Dictionary
var node_events := []
var spatial
var current_tick_num: int
var current_map: String
var mapload
var map
var current_mode: Gamemode
var max_players: int
var history: replay
var recent_ticks = recentHistory.new()
var selfid: int
remote var myping := -1
var ping_timer := 3
var server_snapshot_tick_rate := 90
var recent_history_max_size: int = Engine.iterations_per_second * 10

const default_ip := '127.0.0.1'
const default_port := 25565
const default_browser_port := 25566
const default_local_browser_port := 25567
const miles_ip := '73.234.173.172'
var peer: NetworkedMultiplayerENet
var current_port: int
var current_browser_port: int
var current_local_browser_port: int

var player_scene = preload("res://testing folder/testing player.tscn")
var pause_menu_load
var pause_menu

var default_max_dist_air: float = 40.0 / Engine.iterations_per_second
var default_max_dist_floor: float = 10.0 / Engine.iterations_per_second

# depending on if we want the physics_fps to be able to change while the cilent/
# server is running, maybe make the tick_delta_time a const instead of a var?
var tick_delta_time_ms: int = 1000 * (1.0 / Engine.iterations_per_second)
remote var number_of_ticks_behind: int = clamp(ceil(0.001 * myping * Engine.iterations_per_second), 1, 1000)

# this needs to be set up better so that its scalable for different player speeds
# these calculate the tolerances of the game to check if it needs to perform corrections
# on position
remote var max_dist_air: float = default_max_dist_air * number_of_ticks_behind
remote var max_dist_floor: float = default_max_dist_air * number_of_ticks_behind

# replay and tick stuff:
const save_path = "res://userdata/replays/"

func recalculate_ticks_behind(ping: int) -> int:
	return int(clamp(ceil(0.001 * ping * Engine.iterations_per_second), 1, 1000))

func recalculate_max_dist(dist: float, ticks_behind: int) -> float:
	return dist * ticks_behind

class tick:
	var ticknum: int
	var players: Dictionary
	var events: Array
	var is_snapshot_tick: bool
	
	func _init(this_num: int, this_playerlist: Dictionary):
		ticknum = this_num
		players = this_playerlist
	
	func add_event(which: tick_event):
		events.append(which.export_event())
	
	func export_tick() -> Dictionary:
		return {
			"ticknum": ticknum,
			"players": players,
			"events": events,
			"is_snapshot_tick": is_snapshot_tick
		}

class replay:
	var tick_history: Array
	var tickrate: float
	var snapshot_tick_rate: int
	var lifetime_dirtied_set
	
	func _init(this_history: Array, rate: float, snapshot_rate: int):
		tick_history = this_history
		tickrate = rate
		snapshot_tick_rate = snapshot_rate
	
	func add(this_tick: tick):
		tick_history.append(this_tick.export_tick())
	
	func get_tick(tick: int):
		return tick_history[tick]

func _dump_replay(this_replay: replay):
	var clientorserver: String
	if get_tree().is_network_server():
		clientorserver = "server replay "
	else:
		clientorserver = "client replay "
	var this_datetime = OS.get_datetime()
	var datetime_string = str(str(this_datetime["month"]) + "-" + str(this_datetime["day"]) + "-" + str(this_datetime["year"]) + "; " + str(this_datetime["hour"]) + "-" + str(this_datetime["minute"]) + " (" + str(this_datetime["second"]) + ")")
	# if all unique ID's are enclosed in curly brackets, then we should just add a space to these strings. but if we
	# ever do wind up deploying to web, then keeping the normal brackets as an indication of if there is no hardware
	# ID might be useful... so they're staying in for now
	var os_id_string = str(" [" + OS.get_unique_id() + "]")
	if this_replay != null:
		if this_replay.tick_history != []:
			var replay_file = File.new()
			replay_file.open(save_path + clientorserver + datetime_string + os_id_string + ".txt", File.WRITE)
			replay_file.store_string(var2str(this_replay))
			replay_file.close()
			print("dumped " + clientorserver + datetime_string + " at " + save_path)
		else:
			print("failed to dump " + clientorserver + datetime_string + ". replay " + str(this_replay) + " history is empty")
	else:
		print("failed to dump replay " + datetime_string + ". replay has not been instanced")

#for calling one-shot literal "events" that occur. A gun being fired, someone
# dying, a point being updated, etc.
# maybe this should just be set up with signals, but here it is for now
class tick_event:
	#what object is calling the event (unique ID's for individual players, 0 for
	# all players, and 1 for the server). should probably rework this so that all
	# machines have an array of associations that can be called, such that these
	# vars dont need to be excessively long for players and reduce badnwidth
	# footprint. but to be entirely honest, since this is all testing, and a better
	# system may be implemented, I won't even take the time to add that kind
	# of functionality for all machines
	var to: int
	var from: int
	# maybe this should be an enumerated int
	var action: int
	
	func _init(set_to: int, set_from: int, set_action: int):
		to = set_to
		from = set_from
		action = set_action
	
	func export_event() -> Array:
		return [to, from, action]

class recentHistory:
	var tick_history: Array = []
	
	func add(this_tick: tick) -> void:
		tick_history.append(this_tick.export_tick())
	
	func size() -> int:
		return tick_history.size()
	
	func remove(id: int) -> void:
		tick_history.remove(id)


# why I don't just set up this as something integrated with the recentHistory
# class, I frankly have absolutely zero fuckin clue. Also, why is recentHistory
# one word with capitalizations? idk most of my other shit uses underscores.
# holy fuck im bad at this
func append_to_recent_history(this_tick: tick):
	recent_ticks.add(this_tick)
	if recent_ticks.size() >= recent_history_max_size:
		for i in range (recent_ticks.size() - recent_history_max_size):
			recent_ticks.remove(i)
	

func append_to_history(this_tick: tick):
	history.tick_history.append(this_tick.export_tick())
	append_to_recent_history(this_tick)

class playerdata:
	var position: Vector3
	var direction: Vector3
	var velocity: Vector3
	var aim_angle: Vector2
	var hp: int
	var onfloor: bool
	var dead: bool
	var inputs: Array
	var team: int
	var username: String
	var id: int
	var weapons: Array
	var crouching: bool
	var current_weapon: int

# This could totally just be integrated into the playerdata class, as part of
# the _init() function, but I guess I'm just a pepega. Too bad!
# nevermind. apparently the fucking PLAYERLIST isnt declared if this isnt part of
# the main test class. fucks sake.
func generate_info(id: int) -> Dictionary:
	var data := {}
	var this_player = playerlist[id]
	data.id = id
	data.position = this_player.get_global_transform_origin()
	data.direction = this_player.get_direction()
	data.velocity = this_player.get_velocity()
	data.aim_angle = this_player.get_aim_angle()
	data.hp = this_player.get_hp()
	data.onfloor = this_player.is_on_floor()
	data.dead = this_player.get_dead()
	data.inputs = this_player.get_inputs()
	data.weapons = this_player.get_weapons()
	data.crouching = this_player.get_crouching()
	data.current_weapon = this_player.get_current_weapon()
	return data
	#vars not already implemented
	#data.team = this_player.team
	#data.username = this_player.myname

# do I even fucking need this?!?!? aoglk haslkfgjsdklf
func generate_info_lite(id: int) -> Dictionary:
	var data := {}
	var this_player = playerlist[id]
	data.position = this_player.get_global_transform_origin()
	data.direction = this_player.get_direction()
	data.velocity = this_player.get_velocity()
	data.onfloor = this_player.is_on_floor()
	return data


func generate_tick():
	var this_tick = tick.new(current_tick_num, {})
	for player in playerlist:
		this_tick.players[player] = generate_info(player)
	return this_tick


# might be depreciated, since I'm reworking the code for a player to just send their playerdata, not
# inside a tick. keeping it around cuz it might be useful later, since we might
# want to check in about whether or not client agrees where certain objects are
# along with the server. currently, as-is, this could be done in 1 line, but if
# I'm not gonna ever use it, I might as well not take any time rewriting it to 1
# line... Even though I like just spent some time tripling the size of this comment.
# Oops. Too bad!
func generate_prediction():
	var this_tick = tick.new(current_tick_num, {})
	this_tick.players[playerlist[selfid]] = playerlist[selfid].generate_info()
	return this_tick

func apply_tick(this_tick: tick):
	# maybe initialize vars up here and just change them accordingly in the for
	# loop?
	for player in playerlist:
		var predicted_player = generate_info_lite(player)
		# might want to set up this so that players are properly spawned in and
		# stuff, but otherwise naw. also currently this creates an error because
		# you can't call has_node from a Spatial since the argument being passed
		# is the object itself, and not the nodepath
#		if spatial.has_node(playerlist[player]):
		var current_player = playerlist[player]
		#checks if the player's id 
		if !current_player.is_network_master():
			current_player.inputs.inputs = this_tick.players[player].inputs
			current_player.inputs.input_angle = this_tick.players[player].aim_angle
		
		var max_dist: float
		# checking for false so that if it checks one as true (which is more
		# likely than it being false), then it immediately goes to the else
		# line instead of checking for the player being on the floor for both
		if predicted_player.onfloor == false && this_tick.players[player].onfloor == false:
			max_dist = max_dist_air
		else:
			max_dist = max_dist_floor
		
		var difference: Vector3 = (predicted_player.position - this_tick.players[player].position).abs()
		if difference.x > max_dist || difference.y > max_dist || difference.z > max_dist:
			print(myping)
			print(number_of_ticks_behind)
#			print(myping)
#			print(max_dist)
#			print(current_player.global_transform.origin)
#			print(this_tick.players[player].position)
#			print(default_max_dist_air)
#			print(max_dist_air)
#			print(default_max_dist_floor)
#			print(max_dist_floor)
			current_player.global_transform.origin = this_tick.players[player].position
#			print("correcting player position...")
		
		for event in this_tick.events:
			print(event)
#		
#		this doesnt work and doesnt properly reconcile stuff
#		
#		var max_dist: float
#		var player_past= recentHistory.tick_history[number_of_ticks_behind].players[player]
#
#		# checking for false so that if it checks one as true (which is more
#		# likely than it being false), then it immediately goes to the else
#		# line instead of checking for the player being on the floor for both
#		if player_past.onfloor == false && this_tick.players[player].onfloor == false:
#			max_dist = max_dist_air
#		else:
#			max_dist = max_dist_floor
#		var difference: Vector3 = (this_tick.players[player].position - player_past.position).abs
#		if difference.x > max_dist || difference.y > max_dist || difference.z > max_dist:
#			current_player.global_transform.origin = player_past.position
#		
#
#
		#might be a way to optimize these thingies by turning all the player's gameplay vars into a dictionary
#			current_player.position = this_tick.players[player].position
#			current_player.direction = this_tick.players[player].direction
#			current_player.velocity = this_tick.players[player].velocity
		#since i'm lazy and this is a test, I haven't written all the var changes yet. should do that
		# if this goes anywhere

func _ready():
	current_tick_num = 0
	set_physics_process(false)
	_begin_listen_for_servers()
	_make_advertisement_timer()

#server-exclusive behavior
###############################################################################

func _create_server(this_map, mode: Gamemode, playercount: int, port: int = default_port, browser_port: int = default_browser_port, local_browser_port: int = default_local_browser_port, is_local: bool = true):
	if peer != null:
		peer.close_connection()
	current_map = this_map
	#maybe could be shortened to just map = load(this_map).instance()
	mapload = load(this_map)
	map = mapload.instance()
	current_mode = mode
	max_players = playercount
	print("creating server at IP " + str(IP.get_local_addresses()) + " on port " + str(default_port))
	print("current map: " + str(this_map))
	print("current mode: " + str(mode))
	print("max players: " + str(max_players))
	peer = NetworkedMultiplayerENet.new()
	if port == null:
		port = default_port
	peer.set_server_relay_enabled(false)
	peer.create_server(port, playercount)
	current_port = port
	current_browser_port = browser_port
	current_local_browser_port = local_browser_port
	get_tree().set_network_peer(peer)
	peer.connect("peer_connected", self, "_on_client_connected")
	peer.connect("peer_disconnected", self, "_on_client_disconnected")
	peer.set_target_peer(0)
	$test_menu.hide()
	add_child(map)
	history = replay.new([], Engine.iterations_per_second, server_snapshot_tick_rate)
	set_physics_process(true)
	spatial = map
	OS.set_window_fullscreen(false)
	OS.set_window_size(Vector2(1200, 675))
	Engine.set_target_fps(Engine.iterations_per_second)
	_begin_advertising_server_in_browser(local_browser_port)
	if is_local == false:
		_begin_advertising_online()
	pause_menu_load = load("res://interface/Menus/server menu.tscn")
	pause_menu = pause_menu_load.instance()
	add_child(pause_menu)
	# doing stuff that should do in the server menu script because I'm too lazy
	# to add variables in the test function so that other functions can directly
	# access the server's basic info. this is dumb, but fuck you!
	pause_menu.is_local.set_text(str(is_local))
	pause_menu.online_browser_port.set_text(str(browser_port))
	# change this so it isn't hardcoded
	pause_menu.destination_IP.set_text(miles_ip)
	pause_menu.port.set_text(str(port))

func _on_client_connected(id):
	#log in the console that a player connected
	print("client " + str(id) + " connected")
	#should add an event to the replay/history file that a player connected
	# to the server
	
	#sets up the timer that dictates how often the server pings players to check
	#what their ping is
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = ping_timer
	timer.process_mode = Timer.TIMER_PROCESS_IDLE
	timer.set_name("ping_timer_for_" + str(id))
	add_child(timer)
	rpc_id(id, "on_server_joined", current_map, current_mode, max_players, current_tick_num, playerlist, history.get_tick(current_tick_num - 1))
	player_pings[id] = 0
	_ping_player(id)
	rpc("add_player_to_server", id)
	pause_menu.add_player(id)

func create_player_first_time(id: int):
	var playerinst = player_scene.instance()
	playerinst.set_network_master(id)
	playerinst.spawn(Vector3(1,1,1), preloader.get_resource(current_mode.player_gun_1).instance(), preloader.get_resource(current_mode.player_gun_2).instance())
	spatial.add_child(playerinst)
	playerlist[id] = playerinst

func _on_client_disconnected(id):
	print("client " + str(id) + " disconnected")
	# check delete player for why this should be different
	rpc("delete_player", id)
	pause_menu.delete_player(id)
	
	

# shouldnt be a remotesync func. this should be running since everyone gets a
# tick event telling them to disconnect the player
remotesync func delete_player(id: int):
	playerlist[id].queue_free()
	playerlist.erase(id)

remotesync func add_player_to_server(id: int):
	create_player_first_time(id)

###############################################################################

#client-exclusive functions
###############################################################################

remote func on_server_joined(this_map, mode: Gamemode, playercount: int, current_tick: int, new_playerlist: Dictionary, current_info: tick):
	current_map = this_map
	mapload = load(this_map)
	map = mapload.instance()
#	current_mode = mode
	current_mode = Gamemode.new()
	max_players = playercount
	current_tick_num = current_tick
	history = replay.new([], Engine.iterations_per_second, server_snapshot_tick_rate)
	set_physics_process(true)
	selfid = get_tree().get_network_unique_id()
	add_child(map)
	$test_menu.hide()
	spatial = map
	pause_menu_load = load("res://interface/Menus/player pause menu.tscn")
	pause_menu = pause_menu_load.instance()
	add_child(pause_menu)
	for player in new_playerlist:
		if player != selfid:
			create_player_first_time(player)

func join_server(username = OS.get_environment("USERNAME"), this_ip = default_ip):
	if peer != null:
		peer.close_connection()
	#yes this is hella redundant
	if this_ip == '':
		this_ip = default_ip
	advertisement_timer.set_paused(true)
	advertisement_timer.set_wait_time(advertisement_interval)
	
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(this_ip, default_port)
	get_tree().set_network_peer(peer)
	peer.connect("connection_succeeded", self, "_on_connection_succeeded")
	peer.connect("connection_failed", self, "_on_connection_failed")
	peer.set_target_peer(1)
	print("attempting to connect to host " + str(this_ip))

func _on_connection_succeeded():
	print("connection established")
	peer.connect("server_disconnected", self, "_on_server_disconnected")

func _on_connection_failed():
	print("connection failed")

func _on_server_disconnected():
	print("SERVER DISCONNECTED")
	return_to_testgd()

# yep its basically the same from the rest
func _disconnect_from_server():
	print("disconnecting from server...")
	peer.close_connection()
	return_to_testgd()

remote func _on_update_recieved(authticknum: int, authplist: Dictionary):
	var authtick = tick.new(authticknum, authplist)
	if authticknum != current_tick_num:
		pass
		#do something, since alarm bells should be ringing everywhere
	append_to_history(authtick)
	apply_tick(authtick)
	rpc_unreliable_id(1, "client_update", generate_info(selfid), current_tick_num)

###############################################################################

#might not want to do this, since each type of node should probably use their own unique version of the
# simulate function. at the same time, i like seeing this thing with the green part of it. the colors
# look nice, so i'm keeping it.
func simulate(target_node: Node):
	pass

func _physics_process(delta):
	current_tick_num += 1
	if get_tree().is_network_server():
		#might not need to tell them to simulate
#		spatial.simulate()
		# see testing player.gd _physics_process() for details on why this was
		# commented out.
#		for child in get_tree().get_nodes_in_group("players"):
#			pass
			#UNCOMMENT THIS SOON, dunno if we want to take the player inputs from the tick that's
			#considered to be the previous tick, or like this tick. cuz current_tick_num has been
			#updated already, and I'm too lazy to figure out which order everything happens in yet
			#####################################################
			#child.simulate(this_tick.players[player].inputs)
			#####################################################
		#there is a chance that, depending on how godot works, that the generate_tick() function might run
		# as many times as there are players, if I were to put it in the rset function. which would be bad.
		# so i didn't.
#		print("bouta make a tick")
#		print(Engine.get_physics_interpolation_fraction())
		var this_tick = generate_tick()
		for event in node_events:
			this_tick.add_event(event)
			print(event)
		node_events.clear()
		rpc_unreliable("_on_update_recieved", this_tick.ticknum, this_tick.players)
		append_to_history(this_tick)
		pause_menu.update_player_readouts()

remote func client_update(data: Dictionary, current_tick: int):
	
	var player = get_tree().get_rpc_sender_id()
	for input in data.inputs.size():
		playerlist[player].inputs.inputs[input] = data.inputs[input]
	playerlist[player].inputs.input_angle = data.aim_angle

#this is not working properly rn btw
func _correct_player_location(player: int):
	var max_dist: float
	var player_past= recentHistory.tick_history[number_of_ticks_behind].players[player]
	if player_past.onfloor == true:
		max_dist = max_dist_floor
	else:
		max_dist = max_dist_air
	var difference: Vector3 = (playerlist[player].global_transform.origin - player_past.position).abs()
	if difference.x > max_dist || difference.y > max_dist || difference.z > max_dist:
		playerlist[player].global_transform.origin = player_past.position

#player ping funcs

func _ping_player(id: int):
	print("pinging player %s..."%[id])
	var timer = get_node("ping_timer_for_" + str(id))
	timer.start()
	rpc_unreliable_id(id, "_ping_server")
	print("connecting ping timeout...")
	print(timer.get_wait_time())
	timer.connect("timeout", self, "_on_ping_timeout", [id], 4)

remote func _ping_server():
	print("PINGING SERVER")
	rpc_unreliable("_calculate_ping", selfid)

remote func _calculate_ping(id: int):
	print("ping from %s recieved" %[id])
	var ping_id = get_tree().get_rpc_sender_id()
	#get_node is pretty slow apparently so this should probs just be a reference
	# to a node in like an array or something
	var timer = get_node("ping_timer_for_" + str(id))
	print(timer.get_wait_time())
	if ping_id != id:
		id = ping_id
		#also monkaW because they should be the same
	var newping = int((ping_timer - timer.get_time_left()) * 1000)
	# checks if the ping difference warrants the player updating how many
	# ticks from the server the client is (on the clients end)
	if abs(newping - player_pings[id]) > tick_delta_time_ms:
		print("recalculating info")
		var new_ticks_behind = recalculate_ticks_behind(newping)
		# im setting these from unreliables to plain rsets for a bit. maybe change them back. we'll see.
		rset_id(id, "number_of_ticks_behind", new_ticks_behind)
		rset_id(id, "max_dist_air", recalculate_max_dist(default_max_dist_air, new_ticks_behind))
		rset_id(id, "max_dist_floor", recalculate_max_dist(default_max_dist_floor, new_ticks_behind))
	rset_unreliable_id(id, "myping", player_pings[id])
	timer.disconnect("timeout", self, "_on_ping_timeout")
	timer.connect("timeout", self, "_ping_player", [id], 4)
	rset_unreliable("player_pings", player_pings)

#depreciated since it's now an rset func directly from _calculate_ping
#remote func _get_my_ping(ping: int):
#	myping = ping

func _on_ping_timeout(id: int):
#	print("ping on " + str(id) + " unsuccessful. retrying...")
	_ping_player(id)


#button presses

func _on_server_button_xd_pressed():
	_create_server("res://testing folder/network test map.tscn", Gamemode.new(), 10, default_port, default_browser_port, default_local_browser_port, $test_menu/LocalChecker.is_pressed())
	OS.set_window_title("Quack - SERVER")
	if get_tree().root.world.get_fallback_environment() != get_tree().root.world.get_environment():
		get_tree().root.world.set_environment(get_tree().root.world.get_fallback_environment())


func _on_client_button_xd_pressed():
	var my_username: String
	if $test_menu/username.text == "":
		my_username = "this person is lazy"
	else:
		my_username = $test_menu/username.text
	join_server(my_username, ip_to_connect_to)

var ip_to_connect_to: String
func _on_server_ip_text_changed(new_text):
	ip_to_connect_to = new_text


func _on_username_text_changed(new_text):
	pass # Replace with function body.

func _notification(notif):
	if notif == 1006:
		if get_tree().is_network_server():
			_shut_down_server()
		else:
			_dump_replay(history)

func _input(event):
	if Input.is_action_just_pressed("dump replay"):
		_dump_replay(history)
#	this input if action just pressed ui cancel stuff has been moved to the
#	pause menu scripts themselves
#	if Input.is_action_just_pressed("ui_cancel"):
#		if pause_menu:
#			pause_menu.show()
	# server camera controls
#	if spatial != null:
#		if Input.is_action_pressed("shoot"):
#			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
#			var server_camera = spatial.get_node("Camera")
#			if event is InputEventMouseMotion:
#					server_camera.rotate_y(deg2rad(event.relative.y))
#			if Input.is_action_pressed("forward"):
#				server_camera.global_transform.origin.z -= 0.1
#			if Input.is_action_pressed("back"):
#				server_camera.global_transform.origin.z += 0.1
#			if Input.is_action_pressed("left"):
#				server_camera.global_transform.origin.x -= 0.1
#			if Input.is_action_pressed("right"):
#				server_camera.global_transform.origin.x += 0.1
#			if Input.is_action_pressed("jump"):
#				server_camera.global_transform.origin.y += 0.1
#			if Input.is_action_pressed("crouch"):
#				server_camera.global_transform.origin.y -= 0.1
#		elif Input.is_action_just_released("shoot"):
#			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_quit_pressed():
	_dump_replay(history)
	if get_tree().is_network_server():
		_shut_down_server()
	get_tree().quit()


func _on_back_to_main_pressed():
	get_tree().change_scene("res://interface/Menus/developer main menu.tscn")


# local server browser stuff
var browserlistener: PacketPeerUDP
var online_advertiser: PacketPeerUDP
var advertisement_timer = Timer.new()
var advertisement_interval := 5
var browser_list: Dictionary

func _begin_advertising_server_in_browser(on_port := default_local_browser_port):
	browserlistener.close()
	browserlistener.set_broadcast_enabled(true)
	browserlistener.set_dest_address("255.255.255.255", on_port)
	advertisement_timer.disconnect("timeout", self, "_check_for_servers")
	advertisement_timer.connect("timeout", self, "_advertise_server")

func _begin_advertising_online(on_port := default_browser_port):
	online_advertiser = PacketPeerUDP.new()
	online_advertiser.set_dest_address(miles_ip, on_port)
	print(on_port)
	online_advertiser.set_broadcast_enabled(true)
	advertisement_timer.connect("timeout", self, "_advertise_online")

func _advertise_online():
	print("---------------------")
	print("advertising online...")
	online_advertiser.put_packet(to_json([current_mode.gamemode_name, current_map, max_players, playerlist.size(), current_port]).to_ascii())

#why is it not a built in node for the scene? idk fuck you
func _make_advertisement_timer():
	advertisement_timer.wait_time = advertisement_interval
	advertisement_timer.one_shot = false
	advertisement_timer.autostart = true
	add_child(advertisement_timer)

func _advertise_server():
	print("----------------------")
	print("advertising locally...")
	browserlistener.put_packet(to_json([current_mode.gamemode_name, current_map, max_players, playerlist.size()]).to_ascii())

func _begin_listen_for_servers(on_port := default_local_browser_port):
	if browserlistener:
		browserlistener.close()
		browserlistener.set_broadcast_enabled(false)
	else:
		browserlistener = PacketPeerUDP.new()
	advertisement_timer.disconnect("timeout", self, "_advertise_server")
	if online_advertiser:
		advertisement_timer.disconnect("timeout", self, "_advertise_online")
		online_advertiser.close()
		online_advertiser.set_broadcast_enabled(false)
	
	advertisement_timer.connect("timeout", self, "_check_for_servers")
	browserlistener.listen(on_port)
	print("listening for servers...")
	advertisement_timer.set_paused(false)

func _check_for_servers():
	print("-------------------------------------------------------------------")
	print("polling for local servers...")
	for each_packet in browserlistener.get_available_packet_count():
		var serverIP = browserlistener.get_packet_ip()
		var serverport = browserlistener.get_packet_port()
		var packet = browserlistener.get_packet()
		print("-------------------------------------")
		print("server browser packet recieved from ip %s on port %s" % [serverIP, serverport])
		
		if serverIP != '' and serverport > 0:
			print("valid server detected!")
			if browser_list.has(serverIP) == false:
				print("adding server to list...")
				var info = parse_json(packet.get_string_from_ascii())
				info.append(OS.get_unix_time())
				browser_list[serverIP] = info
				print("server detected on IP %s with port %s" % [serverIP, serverport])
				_register_server_in_browser(serverIP, info[0], info[1], info[2], info[3])
#				_register_server_in_browser(serverIP, info.gamemode_name, info.current_map, info.max_players, )
			else:
				print("server %s %s still connected" % [serverIP, serverport])
				browser_list[serverIP][4] = OS.get_unix_time()
	for server in browser_list:
		if OS.get_unix_time() - browser_list[server][4] > (2 * advertisement_interval):
			browser_list[server][5].queue_free()
			browser_list.erase(server)

func _register_server_in_browser(server_addy: String, server_mode: String, server_map: String, max_server_players: int, current_player_count: int):
	var button = ToolButton.new()
	$test_menu/server_browser_container/server_browser_list.add_child(button)
	# this makes the font too big lmao
#	button.set("custom_fonts/font", preloader.get_resource("button font"))
	button.set_text(server_addy + " | " + server_mode + " on " + server_map + " | " + str(current_player_count) + " out of " + str(max_server_players) + " players")
	button.connect("pressed", self, "join_server", ["joined from server browser", server_addy])
	browser_list[server_addy].append(button)
#	join_server(my_username, ip_to_connect_to)

func queue_event(event: tick_event):
	node_events.append(event)

# idk why this func isnt renamed and just ran on both the client and the server,
# since the actions that need to be taken on different clients are literally
# the fucking same. like, literally. since the close_connection() func can be
# ran on both a client and a server to the same effect... FU OKJFAS LKJ::
func _shut_down_server():
	print("shutting down server...")
	print("disconnecting peers...")
#	for player in playerlist:
#		peer.disconnect_peer(player)
	peer.close_connection()
	return_to_testgd()

func return_to_testgd():
	$test_menu.show()
	print("freeing map from memory...")
	map.queue_free()
	print("resetting ticknum")
	current_tick_num = 0
	print("dumping replay...")
	_dump_replay(history)
	print("clearing tick history")
	history = null
	print("clearing playerlist")
	playerlist.clear()
	set_physics_process(false)
	_begin_listen_for_servers()
	print("freeing pause menu from memory...")
	pause_menu.queue_free()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

var selfpeer: NetworkedMultiplayerENet

func _on_host_button_xd_pressed():
	_create_server("res://testing folder/network test map.tscn", Gamemode.new(), 10, default_port, default_browser_port, default_local_browser_port, $test_menu/LocalChecker.is_pressed())
	OS.set_window_title("Quack - HOST")
	if get_tree().root.world.get_fallback_environment() != get_tree().root.world.get_environment():
		get_tree().root.world.set_environment(get_tree().root.world.get_fallback_environment())


# this doesnt seem to help all that much. but, hey. we'll take what we can get.
func _on_headless_button_xd_pressed():
	_create_server("res://testing folder/network test map.tscn", Gamemode.new(), 10, default_port, default_browser_port, default_local_browser_port, $test_menu/LocalChecker.is_pressed())
	OS.set_window_title("Quack - SERVER")
	get_tree().root.world.set_environment(load("res://testing folder/headless_environment.tres"))
	get_tree().root.set_disable_3d(true)
	pause_menu.show()
