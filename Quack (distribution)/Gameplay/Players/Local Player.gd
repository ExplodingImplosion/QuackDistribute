extends PlayerInterface
class_name LocalPlayer

var my_device_id: int
var HUD: PlayerHUD

var inputs: PoolByteArray
var sens: float = get_sens_setting()
var input_walk_factor: float = 1.0
# might not need this var tbh
var is_inputting_walk: bool = false


signal mouse_moved(event)

func _ready() -> void:
	if OS.is_debug_build():
		set_name("Local Player %s"%[my_device_id])
	set_process(false)
	set_process_input(false)

func _init(device_id: int):
	my_device_id = device_id
	HUD = Lobby.my_client.HUD
	HUD.hide()

# so what's the deal with this whole input += and -= 1, without resetting it until
# the physics process 'ticks' it? basically, the idea is that using this _process(),
# the script figures out whether or not between ticks the player inputted in a given
# direction more or less than the others. then it gets clamped to 1 and 0

func get_keyboard_inputlist() -> void:
	inputs = InputList.get_keyboard_inputlist()

func _process(delta: float):
	tick_player(delta)
#	my_playercontroller.parse_inputs(inputs)
	# the way that get_keyboard_inputlist currently works, this clear_inputs()
	# bit shouldnt need to be called, but in case inputs arent getting cleared,
	# uncomment this 
#	clear_inputs()

func _physics_process(delta: float):
	# hopefully this doesnt cause issues
	clear_inputs()
	call_deferred("reset_advanced_inputs")
	if my_playercontroller:
		record_aim()

func reset_advanced_inputs() -> void:
	advanced_inputs[0] = 1
	for each_input in advanced_inputs.size() - 1:
		advanced_inputs.set(each_input + 1, 0)

func record_aim() -> void:
	aim_angle = my_playercontroller.get_aim_angle()

# this was a good idea but at the same fucking time theres already a shooting
# delta that takes care of this... ffs
#func record_shot() -> void:
#	Lobby.my_client.add_event(TickEvent.FIRE, [Engine.get_physics_interpolation_fraction()])

func add_inputlist_to_advanced_inputlist() -> void:
	advanced_inputs[DELTAFRAMES] += 1
	for input in inputs:
		match input:
			InputList.inputlistenum.FORWARD:
				advanced_inputs[FORWARD] += 1
			InputList.inputlistenum.BACK:
				advanced_inputs[BACK] += 1
			InputList.inputlistenum.LEFT:
				advanced_inputs[LEFT] += 1
			InputList.inputlistenum.RIGHT:
				advanced_inputs[RIGHT] += 1
			InputList.inputlistenum.JUMP:
				advanced_inputs[JUMP] = 1
			InputList.inputlistenum.SHOOT:
				if advanced_inputs[SHOOT] == 0:
					advanced_inputs[SHOOT] = advanced_inputs[DELTAFRAMES]
			InputList.inputlistenum.RELOAD:
				# this might cause desync if the server doesnt slightly delay certain
				# actions if theyre taken on a certain delta frame, since a player buffering
				# a shoot will shoot on their screen, say, + 1 or 2 delta frames after,
				# meanwhile the server will instantly shoot them since it ticks the reload
				# timer down far enough to where the gun is able to shoot. the opposite could also happen,
				# since the reload timer might not tick down enough until a deltaframe, and the player
				# could shoot before the server has ticked that the gun is able to shoot again.
				# this can even be true for stuff like switching weapons timers, etc
				advanced_inputs[RELOAD] = 1
			InputList.inputlistenum.ADS:
				advanced_inputs[ADS] = 1
			InputList.inputlistenum.LASTGUN:
				advanced_inputs[LASTGUN] = 1
			InputList.inputlistenum.GUN1:
				advanced_inputs[GUN1] = 1
			InputList.inputlistenum.GUN2:
				advanced_inputs[GUN2] = 1
			InputList.inputlistenum.MELEE:
				advanced_inputs[MELEE] = 1
			InputList.inputlistenum.CYCLEGRENADES:
				advanced_inputs[CYCLEGRENADES] = 1
			InputList.inputlistenum.MELEEWEAPON:
				advanced_inputs[MELEEWEAPON] = 1
			InputList.inputlistenum.GRENADE:
				advanced_inputs[GRENADE] = 1
			InputList.inputlistenum.CROUCH:
				advanced_inputs[CROUCH] += 1
			InputList.inputlistenum.WALK:
				advanced_inputs[WALK] += 1
			InputList.inputlistenum.DROP:
				advanced_inputs[DROP] = 1
			InputList.inputlistenum.INTERACT:
				advanced_inputs[INTERACT] = 1

#enum	{DELTAFRAMES, FORWARD, BACK, LEFT, RIGHT, JUMP, SHOOT, RELOAD, ADS, GUN1,
#		GUN2, MELEE, CYCLEGRENADES, MELEEWEAPON, GRENADE, CROUCH, WALK, DROP,
#		INTERACT, LASTGUN}

func tick_player(delta: float) -> void:
	if my_playercontroller != null:
		# originally these 2 inputlist func calls were outsiude the my_playercontroller != null check
		get_keyboard_inputlist()
		add_inputlist_to_advanced_inputlist()
		my_playercontroller.parse_input_list(inputs)
	elif is_spectating():
		tick_spectator(delta)

func is_spectating() -> bool:
	return true if team == -1 and is_connected("mouse_moved", self, "aim_spectator_camera") else false

func start_spectating() -> void:
	var freecam = Camera.new()
	freecam.set_znear(0.01)
	freecam.set_zfar(500)
#	if Lobby.my_client.map.get_node_or_null("Perspective Overview Camera") != null:
#		Lobby.my_client.map.add_child_below_node(Lobby.my_client.map.get_node_or_null("Perspective Overview Camera"), freecam)
#	else:
	Lobby.my_client.add_child(freecam)
	# dont do this since stop_spectating uses a really stupid call to this
	# using the nodes name
#	if OS.is_debug_build():
	freecam.set_name("Spectator Free Camera")
	freecam.set_current(true)
	connect("mouse_moved", self, "aim_spectator_camera", [freecam])

func tick_spectator(delta: float) -> void:
	if Input.is_action_just_pressed("shoot"):
		get_current_camera().clear_current()
		if "Ortho" in get_current_camera().get_name():
			get_current_camera().clear_current()
#			print(Lobby.playerIDlist)
#			if Lobby.playerlist.has(Lobby.playerIDlist[0]):
#				if Lobby.playerlist[Lobby.playerIDlist[0]].my_playercontroller != null:
#					Lobby.playerlist[Lobby.playerIDlist[0]].my_playercontroller.go_first_person()
	# this is insanely stupid
	if get_current_camera() != null and get_current_camera().get_name() == "Spectator Free Camera":
		tick_spectator_camera(delta)

func tick_spectator_camera(delta: float) -> void:
	move_spectator_camera(delta)

# holy shit theres a velocity var in the fucking local player script what the actual
# fuck
var velocity: Vector3
func move_spectator_camera(delta: float) -> void:
	var direction: Vector3 = Vector3()
#	var aim: Basis = get_current_camera().global_transform.basis
	if Input.is_action_pressed("forward"):
		direction.z -= 1
	if Input.is_action_pressed("back"):
		direction.z += 1
	if Input.is_action_pressed("left"):
		direction.x -= 1
	if Input.is_action_pressed("right"):
		direction.x += 1
	if Input.is_action_pressed("jump"):
		direction.y += 1
	if Input.is_action_pressed("crouch"):
		direction.y -= 1
	var target: Vector3 = direction
	if Input.is_action_pressed("walk"):
		target = direction / 40
	else:
		target = direction / 10
#	var temp_vel: Vector3()
	velocity = velocity.linear_interpolate(target, 3 * delta)
	# could do this with velocity replaced by temp_vel, but that means that theres
	# no acceleration/decelleration
	get_current_camera().translate(velocity)
	
#	get_current_camera().translate()

func aim_spectator_camera(event: InputEventMouseMotion, freecam: Camera) -> void:
	var direction: Vector2 = apply_sens_to_relative(event.relative)
	freecam.rotation_degrees.y -= direction.x
	freecam.rotation_degrees.x -= direction.y

func get_current_camera() -> Camera:
	return get_tree().get_root().get_camera()

func stop_spectating() -> void:
	var freecam: Camera = Lobby.my_client.get_node_or_null("Spectator Free Camera")
	if freecam != null:
		freecam.queue_free()
	disconnect("mouse_moved", self, "aim_spectator_camera")

func generate_update() -> Array:
	return [my_device_id, advanced_inputs, aim_angle, get_playercontroller_info()]

func get_playercontroller_info() -> Dictionary:
	return my_playercontroller.generate_info() if my_playercontroller != null else {}

func tick_inputs_for_network() -> Array:
	calculate_player_inputdir()
	return tick_inputs

func calculate_player_inputdir() -> void:
	tick_inputs[InputList.inputenum.MOVEMENT] = clamp_vector2(tick_inputs[InputList.inputenum.MOVEMENT])

func _input(event):
	if event is InputEventMouseMotion:
		emit_signal("mouse_moved", event)
	elif Input.is_action_just_pressed("ui_cancel"):
		request_pause()

func aim_player(event: InputEventMouseMotion) -> void:
	my_playercontroller.aim(apply_sens_to_relative(event.relative), true)

func apply_sens_to_relative(relative: Vector2) -> Vector2:
	return relative * sens
	# could also be done as return Vector2(apply_sens_to_float(relative.x), apply_sens_to_float(relative.y))

func apply_sens_to_float(value: float) -> float:
	return value * sens

func input(which_input: int):
	inputs.append(which_input)

func clear_inputs() -> void:
	inputs.resize(0)

#func pause_unpause():
#	if is_processing():
#		pause()
#	else:
#		unpause()

func delete_playercontroller() -> void:
	if my_playercontroller:
		disconnect("mouse_moved", self, "aim_player")
		Lobby.my_client.entities.players.erase(my_playercontroller.owner_id)
		my_playercontroller.queue_free()
		my_playercontroller = null

#func on_playercontroller_deleted() -> void:
#	print("playercontroller deleted")
#
#

func get_sens_setting() -> float:
	return 0.01 * settings.get_setting("Mouse", "Sensitivity")

func request_pause() -> void:
	Lobby.my_client.pause_local_players()

func pause():
	set_process(false)
	set_process_input(false)
	# show pause menu
	# if its not set up for multiple players, then why isnt pausing done from
	# the actual Client.gd script lmfao
	Lobby.my_client.menu._display()

func unpause():
	set_process(true)
	set_process_input(true)
	sens = get_sens_setting()
	# hide pause menu, which should be taken care of by the actual pause menu
	# itself
