extends Control

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
onready var playerpos = $"player Info Container/Position container/setter"
onready var playervel = $"player Info Container/Velocity Container/setter"
onready var playeraim = $"player Info Container/Aim container/setter"
onready var playerdir = $"player Info Container/Direction Container/setter"
onready var playerHP = $"player Info Container/HP Container/setter"
onready var playeronfloor = $"player Info Container/Onfloor Container/readout"
onready var playerping = $"player Info Container/Ping container/setter"
onready var behindbutton = $"player Info Container/Ticks Behind Container/button"
onready var behindsetter = $"player Info Container/Ticks Behind Container/setter"

onready var expected_delta: String = str(1.0 / Engine.iterations_per_second)
onready var stringtickrate: String = str(Engine.iterations_per_second)

var current_player_id := 0
onready var server: NetworkPeer = get_parent()
var console: WindowDialog = preloader.get_resource("Developer Console").instance()
var current_IP_id := 0

func _ready():
	hide()
	set_initial_menus()
	setup_connections()
	setup_console()

func setup_connections() -> void:
	Lobby.peer.connect("peer_connected", self, "add_player")
	Lobby.peer.connect("peer_disconnected", self, "delete_player")

func _on_tree_entered():
	pass

#func setup_server_ui():
#	add_child(menu)
#	menu.is_local.set_text(str(is_local))
#	menu.online_browser_port.set_text(str(Lobby.browser.browser_port))
#	# change this so it isn't hardcoded
#	menu.destination_IP.set_text(Lobby.miles_ip)
#	menu.port.set_text(port)

func set_initial_menus() -> void:
	var addys = IP.get_local_addresses()
	if !ip:
		print('what the actual fuck')
	var my_ip: String
	for addy in addys:
		if addy.split('.').size() == 4 && addy != '127.0.0.1':
			my_ip = addy
			break
#	ip.set_text(addys[addys.size() - 3])
	print(my_ip)
	ip.set_text(my_ip)
	if Lobby.local_advertiser:
		local_browser_port.set_text(str(Lobby.local_advertiser.recieve_port))
		online_browser_port.set_text(str(Lobby.browser.send_port))
	else:
		local_browser_port.set_text(str(Lobby.browser.recieve_port))
		online_browser_port.set_text("None")
	is_local.set_text(str(server.is_local))
	destination_IP.set_text(Lobby.browser.destination_ips[0])
	port.set_text(str(server.port))

func show_next_ip() -> void:
	current_IP_id += 1
	if Lobby.browser.destination_ips.size() > current_IP_id:
		destination_IP.set_text(Lobby.browser.destination_ips[current_IP_id])
	else:
		current_IP_id = 0
		destination_IP.set_text(Lobby.browser.destination_ips[current_IP_id])

func setup_console() -> void:
	add_child(console)
	console.hide()

func _physics_process(delta: float):
	if is_visible():
		update_tickrate_readout()
		# this is being called way too commonly, but since I dont wanna put UI code in test.gd I'm keeping it here
		if current_player_id != 0:
			pass
#			playerping.set_text(str(get_parent().player_pings[current_player_id]))

func update_tickrate_readout():
	var fps = Engine.get_frames_per_second()
#	current_tick.set_text(str(server.current_tick_num))
#	current_time.set_text(str(server.current_tick_num / Engine.iterations_per_second))
	tickrate.set_text("%s/%s" %[fps, stringtickrate])
	deltareadout.set_text("%s/%s" % [1.0/fps, expected_delta])

func update_player_readouts():
	if current_player_id != 0:
		update_readout_conditionally(playerpos,str(get_parent().playerlist[current_player_id].global_transform.origin))
		update_readout_conditionally(playervel,str(get_parent().playerlist[current_player_id].velocity))
		update_readout_conditionally(playeraim,str(get_parent().playerlist[current_player_id].aim_angle))
		update_readout_conditionally(playerdir,str(get_parent().playerlist[current_player_id].direction))
		update_readout_conditionally(playerHP,str(get_parent().playerlist[current_player_id].hp))
		# this readout isn't editable, so it doesn't need to be updated only if it's not in focus
		playeronfloor.set_text(str(get_parent().playerlist[current_player_id].is_on_floor()))

func update_readout_conditionally(readout: Control, newtext: String):
	if !readout.has_focus():
		readout.set_text(newtext)

func _input(event):
	if Input.is_action_just_pressed("ui_cancel") and !get_tree().root.is_3d_disabled():
		if console.is_visible():
			console.hide()
		elif is_visible():
			hide()
		else:
			show()

func add_player(player: int) -> void:
	var button = ToolButton.new()
	player_list.add_child(button)
	button.set_name(str(player))
	button.set("custom_fonts/font", preloader.get_resource("button font"))
	button.set_text(str(player))
	button.connect("pressed", self, "show_player_cam", [player])


func show_player_cam(player: int) -> void:
	if current_player_id != 0:
		Lobby.playerlist[current_player_id].my_playercontroller.go_third_person()
	current_player_id = player
	IDLabel.set_text(str(player))
	if Lobby.playerlist[player].my_playercontroller:
		Lobby.playerlist[player].my_playercontroller.go_first_person()

func delete_player(player: int) -> void:
	if current_player_id == player:
		current_player_id = 0
		_on_camera_reset()
	player_list.get_node(str(player)).queue_free()


func _on_camera_reset():
	if current_player_id != 0:
		if Lobby.playerlist[current_player_id].my_playercontroller:
			Lobby.playerlist[current_player_id].my_playercontroller.go_third_person()
	get_parent().map.get_node("Perspective Overview Camera").set_current(true)


func _on_Dump_Replay_pressed():
	get_parent().history.save()


func _on_Disconnect_Current_Player_pressed():
	if current_player_id == 0:
		print("cannot disconnect a player if a player is not selected!")
	else:
		print("forcefully disconnecting peer %s" % [current_player_id])
		Lobby.peer.disconnect_peer(current_player_id)


func _on_Shut_Down_server_pressed():
	get_parent().shutdown()


func _on_Quit_pressed():
	print("Quitting client...")
	print("disconnecting peers...")
	Lobby.peer.close_connection()
	# idk why im freeing the map from memory here if the server is supposed to be
	# fucking deleted lmfao
#	print("freeing map from memory...")
#	map.queue_free()
	print("saving replay...")
	# save replay
	Quack.quit()


func _on_ticks_behind_changed(new_text: String):
	correct_int_if_wrong(behindsetter, new_text, 0, 50)

# this is the dumbest workaround ive ever fucking experienced lmfaoooooo
func _on_ticks_behind_confirmed(nothing: String = "lol"):
	if current_player_id == 0:
		print("cannot manually change player variables if no player is selected!")
	else:
		print("manually changing ticks behind on player %s to %s" %[current_player_id, behindsetter.get_text()])
		get_parent().manually_set_ticks_behind(current_player_id, int(behindsetter.get_text()))


func _on_ping_entered(new_text: String):
	pass


func _on_position_entered(new_text: String):
	pass # Replace with function body.


func _on_velocity_entered(new_text: String):
	pass # Replace with function body.


func _on_aim_angle_entered(new_text: String):
	pass # Replace with function body.


func _on_direction_entered(new_text: String):
	pass # Replace with function body.


func _on_HP_entered(new_text: String):
	pass # Replace with function body.

func correct_int_if_wrong(node: LineEdit, text: String, min_value: int, max_value: int):
	var correction: String = generate_int_correction(text, min_value, max_value)
	if correction != text:
		node.set_text(correction)

func generate_int_correction(text: String, min_value: int, max_value: int) -> String:
	return str(clamp(int(text), min_value, max_value))


func _on_health_changed(new_text: String):
	correct_int_if_wrong(playerHP, new_text, 0,Lobby.my_client.gamemode.max_player_hp)


func _on_direction_changed(new_text: String):
	pass


func _on_aim_angle_changed(new_text: String):
	pass


func _on_velocity_changed(new_text: String):
	pass


func _on_position_changed(new_text: String):
	pass


func _on_ping_changed(new_text: String):
	correct_int_if_wrong(playerping, new_text, 0, 9999)

func refresh_server():
	server = Lobby.my_client
