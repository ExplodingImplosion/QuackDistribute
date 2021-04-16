extends Control

onready var root = get_parent()

onready var tickrate = $"server Info Container/tickrate container/readout"
onready var deltareadout = $"server Info Container/delta time container/readout"
onready var ip = $"server Info Container/IP container/readout"
onready var port = $"server Info Container/Port container/readout"
onready var local_browser_port = $"server Info Container/Browser port container/readout"
onready var is_local = $"server Info Container/Local? container/readout"
onready var online_browser_port = $"server Info Container/Online port container/readout"
onready var destination_IP = $"server Info Container/Destination container/readout"
onready var player_list = $"Players List"
onready var current_tick = $"tick readout container/Tick Readout"
onready var current_time = $"time readout container/Time Readout"

onready var IDLabel = $"player Info Container/Label"
onready var playerpos = $"player Info Container/Position container/readout"
onready var playervel = $"player Info Container/Velocity Container/readout"
onready var playeraim = $"player Info Container/Aim container/readout"
onready var playerdir = $"player Info Container/Direction Container/readout"
onready var playerHP = $"player Info Container/HP Container/readout"
onready var playeronfloor = $"player Info Container/Onfloor Container/readout"
onready var playerping = $"player Info Container/Ping container/readout"
#onready var  = $"Player Info Container/"

onready var expected_delta: String = str(1.0 / Engine.iterations_per_second)
onready var stringtickrate: String = str(Engine.iterations_per_second)

var current_player_id := 0

func _ready():
	hide()
#	tickrate.set_text(str(Engine.iterations_per_second))
	var addys = IP.get_local_addresses()
	ip.set_text(addys[addys.size() - 3])
	local_browser_port.set_text(str(root.default_local_browser_port))
	# some of the readouts are changed in the _create_server() function on the test
	# script because I'm too lazy to add variables in the test function so that
	# other functions can directly access the server's basic info. this is dumb,
	# but fuck you!


func _physics_process(delta: float):
	if is_visible():
		var fps = Engine.get_frames_per_second()
		current_tick.set_text(str(root.current_tick_num))
		current_time.set_text(str(root.current_tick_num / Engine.iterations_per_second))
		tickrate.set_text("%s/%s" %[fps, stringtickrate])
		deltareadout.set_text("%s/%s" % [1.0/fps, expected_delta])
		# this is being called way too commonly, but since I dont wanna put UI code in test.gd I'm keeping it here
		if current_player_id != 0:
			playerping.set_text(str(get_parent().player_pings[current_player_id]))

func update_player_readouts():
	if current_player_id != 0:
		playerpos.set_text(str(get_parent().playerlist[current_player_id].global_transform.origin))
		playervel.set_text(str(get_parent().playerlist[current_player_id].velocity))
		playeraim.set_text(str(get_parent().playerlist[current_player_id].aim_angle))
		playerdir.set_text(str(get_parent().playerlist[current_player_id].direction))
		playerHP.set_text(str(get_parent().playerlist[current_player_id].hp))
		playeronfloor.set_text(str(get_parent().playerlist[current_player_id].is_on_floor()))

func _input(event):
	if Input.is_action_just_pressed("ui_cancel") and !get_tree().root.is_3d_disabled():
		if is_visible():
			hide()
		else:
			show()

func add_player(player: int):
	var button = ToolButton.new()
	player_list.add_child(button)
	button.set_name(str(player))
	button.set("custom_fonts/font", preloader.get_resource("button font"))
	button.set_text(str(player))
	button.connect("pressed", self, "show_player", [player])


func show_player(player: int):
	get_parent().playerlist[player].switch_from()
	current_player_id = player
	IDLabel.set_text(str(player))
	get_parent().playerlist[player].switch_to()

func delete_player(player: int):
	if current_player_id == player:
		current_player_id = 0
	player_list.get_node(str(player)).queue_free()


func _on_camera_reset():
	if current_player_id != 0:
		get_parent().playerlist[current_player_id].switch_from()
	get_parent().spatial.get_child(1).set_current(true)


func _on_Dump_Replay_pressed():
	get_parent()._dump_replay(get_parent().history)


func _on_Disconnect_Current_Player_pressed():
	if current_player_id != 0:
		print("forcefully disconnecting peer %s" % [current_player_id])
		get_parent().peer.disconnect_peer(current_player_id)
	else:
		print("cannot disconnect a player if a player is not selected!")


func _on_Shut_Down_server_pressed():
	get_parent()._shut_down_server()


func _on_Quit_pressed():
	print("Quitting server...")
	get_parent()._on_quit_pressed()
