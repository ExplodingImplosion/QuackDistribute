extends Menu

onready var main = $"Main Container"
onready var localchecker = $"Host Game Container/Local Checker"
onready var joingamemenu = $"Join Game Container"
onready var garbage = $garbage
onready var hostgamemenu = $"Host Game Container"
onready var createservermenu = $"Create Server Container"
onready var queuemenu = $"Queue Menu"
onready var queuefilters = $"Queue Filters Menu"
onready var serverbrowsermenu = $"Server Browser Container"
onready var directconnectionmenu = $"Direct Connection Container"
onready var isheadless = $"Create Server Container/Create Server Container/Headless Button"
onready var islocal = $"Create Server Container/Create Server Container/Local Button"
onready var map_menu = $"Create Server Container/Select Map Container/Menu"
onready var player_limit_setter = $"Create Server Container/Select Max Players Container/Player Count Setter"
onready var gamemode_menu = $"Create Server Container/Select Mode Container/Menu"
onready var gameplayport = $"Create Server Container/Port Container/Port Setter"
onready var browserport = $"Create Server Container/Browser Port Container/Port Setter"
onready var localbrowserport = $"Create Server Container/Browser Port Container2/Port Setter"
onready var serverbrowserlist = $"Server Browser Container/Server Browser Scroller/Server Browser List"
onready var ipsetter = $"Direct Connection Container/IP Setter"

enum data{ADDY,PORT,PACKET,TIME,BUTTON}
enum info{MAP,MODE,MAXPLAYERS,CURRENTPLAYERS, GAMEPLAYPORT}

func _ready():
	Lobby._begin_polling()
	# this is the dumbest shit in the world. why aren't these accessible in the
	# editor menu, but are still part of the default button stylizing functionalities?
	# also, why the ACTUAL FUCKITY FUCK do you need a custom hover_pressed style
	# in order to make the custom font_cover_hover_pressed actually take effect?
	# HELLO?????????
	localchecker.set("custom_styles/hover_pressed", preload("res://interface/Buttons/Menu Button Pressed.tres"))
	localchecker.set("custom_colors/font_color_hover_pressed", Color("e1fffe"))
	Lobby.browser.connect("server_updated", self, "update_server_in_browser")
	Lobby.browser.connect("server_deleted", self, "clear_server_from_browser")


func _input(event):
	if (Input.is_action_just_pressed("ui_cancel")):
		match current_layer:
			main:
				Lobby._stop_polling()
				get_tree().change_scene("res://interface/Menus/Main Menu.tscn")
			joingamemenu:
				go_to_main()
			hostgamemenu:
				go_to_main()
			createservermenu:
				go_to_main()
			directconnectionmenu:
				_go_to_layer(joingamemenu)
			queuemenu:
				_go_to_layer(joingamemenu)
			queuefilters:
				_go_to_layer(joingamemenu)
			serverbrowsermenu:
				_go_to_layer(joingamemenu)

func go_to_main() -> void:
	_go_to_layer(main)
	garbage.show()

func leave_main(to: Node) -> void:
	garbage.hide()
	_go_to_layer(to)

func _on_Local_Checker_toggled(button_pressed: bool):
	if button_pressed:
		localchecker.set_text("Local")
	else:
		localchecker.set_text("Online")


func _on_Join_Game_Button_pressed():
	leave_main(joingamemenu)


func _on_Host_Game_Button_pressed():
	leave_main(hostgamemenu)


func _on_Create_Server_Button_pressed():
	leave_main(createservermenu)


func _on_Gamemode_selected(id):
	$"Create Server Container/Select Mode Container/Menu"


func _on_server_creation_initiated():
	Lobby.create_server(isheadless.is_pressed(), get_map(), get_gamemode(), get_player_limit(), get_gameplay_port(), get_browser_port(), get_local_browser_port(), is_local())
	start_game()


func _on_Map_selected(id):
	$"Create Server Container/Select Map Container/Menu"


func _on_Player_Count_changed(value: int):
	pass


func _on_port_changed(new_text: String):
	check_text(gameplayport, new_text)


func _on_browser_port_changed(new_text: String):
	check_text(browserport, new_text)


func _on_local_browser_port_changed(new_text: String):
	check_text(localbrowserport, new_text)
	

func check_text(node: LineEdit, new_text):
	if str(int(new_text)) != new_text:
		node.set_text(str(int(new_text)))

func _on_Queue_Button_pressed():
	_go_to_layer(queuemenu)


func _on_Queue_Filters_Button_pressed():
	_go_to_layer(queuefilters)


func _on_Server_Browser_Button_pressed():
	_go_to_layer(serverbrowsermenu)


func _on_Direct_Connection_Button_pressed():
	_go_to_layer(directconnectionmenu)

func add_server_to_browser(server: ServerBrowserDialogue.server_info) -> void:
	var button = Button.new()
	serverbrowserlist.add_child(button)
	button.set("custom_fonts/font", preloader.get_resource("button font"))
	button.set_text_align(Button.ALIGN_CENTER)
	button.set_name(server.ip)
	print("--------")
	print(server.info)
	print(server.ip)
	print(server.info[info.GAMEPLAYPORT])
	print("--------")
	button.connect("pressed", Lobby, "connect_to_server", [server.ip, server.info[info.GAMEPLAYPORT]])
	update_server_in_browser(server)

func update_server_in_browser(server: ServerBrowserDialogue.server_info) -> void:
	# this is hacky and dumb but go fuck yourself
	# (instead of passing around a reference to a button, the button just gets found
	# manually out of the children every time identifying it thru the ip)
	if get_server_button_by_ip(server.ip):
		get_server_button_by_ip(server.ip).set_text(str("%s | %s on %s, %s out of %s players"%
												[   server.ip,
													server.info[info.MODE],
													server.info[info.MAP],
													server.info[info.CURRENTPLAYERS],
													server.info[info.MAXPLAYERS] ] ) )
	else:
		add_server_to_browser(server)

func get_server_button_by_ip(ip: String) -> Button:
	return serverbrowserlist.get_node(ip.replace('.',''))

func clear_server_from_browser(server_ip: String) -> void:
	get_server_button_by_ip(server_ip).queue_free()

func _on_server_directly_connected(this_ip: String = ipsetter.get_text()):
	if this_ip == '':
		this_ip = 'localhost'
	Lobby.connect_to_server(this_ip)

func get_map() -> String:
#	var map: String = map_menu.get_item_text(map_menu.get_selected())
#	return str("res://Maps/%s/%s.tscn"%[map, map])
	return map_menu.get_item_text(map_menu.get_selected())

func get_gamemode() -> Gamemode:
	var mode: String = gamemode_menu.get_item_text(gamemode_menu.get_selected())
	if mode == "Map Default":
		
		pass
	# well this is stupid as fuck
	match mode:
		"Default Gamemode":
			mode = "Default"
		"3v3 Elimination":
			mode = "3v3"
	var this_mode: Gamemode = load(str("res://Gamemodes/%s.tscn"%[mode])).instance()
	var this_mode_exported: Dictionary = this_mode.export_gamemode()
	this_mode.queue_free()
	return Gamemode.new(this_mode_exported)
	# faster but creates an orphan node
#	return Gamemode.new(load(str("res://Gamemodes/%s.tscn"%[mode])).instance().export_gamemode())
	# faster but doesnt add a round timer as a child
#	return load(str("res://Gamemodes/%s.tscn"%[mode])).instance()

func get_player_limit() -> int:
	return player_limit_setter.value

func is_local() -> bool:
	return islocal.pressed

func get_gameplay_port() -> int:
	return int(gameplayport.get_text())

func get_browser_port() -> int:
	return int(browserport.get_text())

func get_local_browser_port() -> int:
	return int(localbrowserport.get_text())

func start_game() -> void:
	get_tree().set_current_scene(Lobby.my_client)
	print(get_tree().current_scene.get_name())
	queue_free()
