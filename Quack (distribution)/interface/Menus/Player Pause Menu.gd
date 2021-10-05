extends Menu

# layers for _go_to_layer() to call
onready var main: VBoxContainer = $"menu container"
onready var settingsmenu: Control = $"settings container"
onready var teammenu: VBoxContainer = $"Team Menu Container"
onready var teamlabel: Label = $"Team Label"
onready var team1button: Button = $"Team Menu Container/Team Menu Sorter/Team 1 Button"
onready var team2button: Button = $"Team Menu Container/Team Menu Sorter/Team 2 Button"
onready var joinbutton: Button = $"Team Menu Container/Team Menu Sorter/Join Match Button"
onready var randombutton: Button = $"Team Menu Container/Extra Buttons Sorter/Random Team Button"

func _ready():
	hide()
	settingsmenu.set_process_input(false)
	set_process_input(false)
	# make sure all the menu icons and settings and whatnot are properly set up
#	print(keybinds.get_child(1).get_name())
#	VisualServer.canvas_item_set_clip(get_canvas_item(), true)


func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		match current_layer:
			main:
				exit()
			settingsmenu:
				if settingsmenu.exit_flag == true:
					var parent = get_parent()
					Lobby.my_client.HUD.crosshair.rebuild_crosshair()
					_go_to_layer(main)
			teammenu:
				leave_team_menu()

func _display():
	get_parent().HUD.hide()
	show()
	set_process_input(true)
	settingsmenu.set_process_input(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func exit() -> void:
	for player in Lobby.local_players:
		if player.my_playercontroller:
			close()
			return
		# lmfao
		elif player.is_spectating():
			_go_to_layer(main)
			close()
			return
	_go_to_layer(teammenu)

func close() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	settingsmenu.set_process_input(false)
	set_process_input(false)
	hide()
	Lobby.my_client.unpause_local_players()
	get_parent().HUD.show()
	# this is now done as a result of the above line of code
#	parent.playerlist[parent.selfid].sens = float(settingsmenu.sensreadout.get_text()) * 0.01

#------------------------------------------------------------------------------
# Individual Button presses/////////////////////////////////////////////////////
#-------------------------------------------------------------------------------

func _on_Settings_Button_pressed():
	_go_to_layer(settingsmenu)


func _on_Server_Browser_Button_pressed():
	pass
	# _go_to_layer(serverbrowser)


func _on_Quit_Button_pressed():
	Quack.quit()


func _on_Disconnect_Button_pressed():
	get_parent().disconnect_from_server()


func _on_Change_Team_Button_pressed():
	if Lobby.my_client.can_change_team():
		go_to_team_select_menu()
	else:
		go_to_join_menu()


var team_select_mode: bool = true

func go_to_team_select_menu() -> void:
	if !team_select_mode:
		set_team_menu_vars()
		team_select_mode = true
	go_to_team_menu()

func go_to_team_menu() -> void:
	if team_select_mode:
		teamlabel.show()
	_go_to_layer(teammenu)

func set_team_menu_vars() -> void:
	team1button.show()
	team2button.show()
	joinbutton.hide()
	randombutton.show()

func go_to_join_menu() -> void:
	if team_select_mode:
		set_join_menu_vars()
		team_select_mode = false
	go_to_team_menu()

func set_join_menu_vars() -> void:
	team1button.hide()
	team2button.hide()
	joinbutton.show()
	randombutton.hide()

func leave_team_menu() -> void:
	if team_select_mode:
		teamlabel.hide()
	_go_to_layer(main)


#func request_team_based_on_mode_team_type(team: int) -> int:
#	match Lobby.my_client.gamemode.params.team_type:
#		Gamemode.FFA:
#

func _on_Team_1_selected():
	request_team_selection(0)


func _on_Team_2_selected():
	request_team_selection(1)


func _on_Spectate_selected():
	request_team_selection(-1)
	# this is incredibly stupid. it looked so nice when all the selections were
	# 1 line long... but fuck it i guess
	
	# if the player is on the spectating team but isnt spectating (theres no spectator freecam etc)
	# then start them spectating since the server isn't going to send a message to the client
	# telling it to start spectating. this is only really relevant when the player first enters the game
	# and wants to spectate first thing.
	if Lobby.get_local_player().team == -1 and !Lobby.get_local_player().is_spectating():
		Lobby.get_local_player().start_spectating()
		exit()
		Lobby.my_client.unpause_local_players()


func _on_Random_Team_selected():
	request_team_selection(-2)

func request_team_selection(team: int) -> void:
	Lobby.rpc_id(1, "on_team_selected", team)


func _on_Join_Match_Button_pressed():
	request_team_selection(0)
