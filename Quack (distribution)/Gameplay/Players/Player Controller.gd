extends KinematicBody
class_name PlayerController

var cam_angle := 0.0
# NOTE: SENS IS NOW STORED IN LOCAL PLAYERS' VARS

var velocity := Vector3()
var direction := Vector3()
var _snap := Vector3()
const FLOOR_NORMAL := Vector3(0, 1, 0)
const FLOOR_MAX_ANGLE := deg2rad(46.0)

var inputdir := Vector2()

var crouching := false
var jumped := false
var walking := false

const maxsp:= 40
const grav := 9.8 * 3
const maxwsp := 6.5
const acceleration := 4
const decceleration := 8
const air_acceleration := 0.25
const air_decceleration := 0.0125
const jump_strength := 10
const crouch_factor := 0.3
const walk_factor := 0.5
const side_relative := 0.85
const back_relative := 0.65

# might move these to another script
const maxhp := 100
var hp : float = maxhp

var dead := false

var this_crouch_factor:= 1.0
var this_walk_factor:= 1.0

var team: int = 0

var weapons := [null, null, null]
var current_weapon_idx := 0
var current_weapon: BaseWeapon
var last_weapon_idx := 1
var last_weapon: BaseWeapon

var grenades := []
var current_nade = null

var owner_id: int

onready var cam: Camera = $"Head/World Camera"
onready var third_person_model: MeshInstance = $"Third Person Model"
onready var viewmodel_hands: MeshInstance = $"Head/Viewmodel Hands"
onready var beak: MeshInstance = $"Head/Beak"
onready var head = $Head

func get_aim_angle() -> Vector2:
	return Vector2(rotation_degrees.y, head.rotation_degrees.x)

# these could all actually be strings that get passed to call() functions instead
# of funcrefs

var shootfunc: FuncRef
var reloadfunc: FuncRef
var ADSfunc: FuncRef
var leaveADSfunc: FuncRef
var drawfunc: FuncRef
var guntickfunc: FuncRef

signal died
signal health_changed(new_health)
signal orientation_updated(new_orientation)
signal ammo_updated(new_ammo)
signal reserve_ammo_updated(new_ammo)

#func _init(owner_id: int, start_location: Vector3, gun_1: BaseWeapon, gun_2: BaseWeapon, this_team: int):
#	create(owner_id, start_location, gun_1, gun_2, this_team)

# ong we might want to use just this_owner_id to determine the team, since I don't
# think there's gonna be a circumstance in which the player character will have
# a different team than their owner's team...
func create(this_owner_id: int, start_transform: Transform, gun_1: BaseWeapon, gun_2: BaseWeapon, this_team: int) -> PlayerController:
	spawn(start_transform, gun_1, gun_2)
	initialize_owner(this_owner_id, this_team)
	# since drawing a weapon calls a function determined by the owner and their
	# relation to the game's networking, drawing the current weapon needs to be
	# called outside of spawn, and after initializing the owner. meanwhile,
	# spawning needs to come before initializing the owner, since a bunch of the
	# owner-assigning-related functions require nodes to be part of the scenetree
	draw_current_weapon()
	# not using this anymore since this fired during like idle frame or something and that fucked up the order of shit
#	connect("tree_exiting", Lobby.playerlist[this_owner_id], "on_playercontroller_deleted")
	return self

# see create function comment
func initialize_owner(this_owner_id: int, this_team: int) -> void:
	owner_id = this_owner_id
	team = this_team
	set_network_master(owner_id)
	if OS.is_debug_build():
		set_name(str(owner_id))
	assign_functions_based_on_owner_type()

func assign_functions_based_on_owner_type() -> void:
	if get_tree().is_network_server():
		assign_server_funcs()
	elif is_network_master():
		assign_local_funcs()
	else:
		assign_remote_funcs()

func assign_server_funcs() -> void:
	shootfunc = funcref(self, "servershoot")
	reloadfunc = funcref(self, "serverreload")
	ADSfunc = funcref(self, "serverADS")
	leaveADSfunc = funcref(self, "serverleaveADS")
	drawfunc = funcref(self, "serverdraw")
	guntickfunc = funcref(self, "serverguntick")

func assign_local_funcs() -> void:
	shootfunc = funcref(self, "localshoot")
	reloadfunc = funcref(self, "localreload")
	ADSfunc = funcref(self, "localADS")
	leaveADSfunc = funcref(self, "localleaveADS")
	drawfunc = funcref(self, "localdraw")
	guntickfunc = funcref(self, "localguntick")

func assign_remote_funcs() -> void:
	shootfunc = funcref(self, "remoteshoot")
	reloadfunc = funcref(self, "remotereload")
	ADSfunc = funcref(self, "remoteADS")
	leaveADSfunc = funcref(self, "remoteleaveADS")
	drawfunc = funcref(self, "remotedraw")
	guntickfunc = funcref(self, "remoteguntick")

func _ready():
	pass

enum {FORWARD, BACK, LEFT, RIGHT, JUMP, SHOOT, RELOAD, ADS, GUN1, GUN2, MELEE, CYCLEGRENADES, MELEEWEAPON, GRENADE, CROUCH, WALK, DROP, INTERACT, LASTGUN}
enum {PRIMARY, SECONDARY, MELEESLOT, GRENADES}
enum inputenum {MOVEMENT, JUMP, SHOOT, RELOAD, ADS, GUN1, GUN2, MELEE, CYCLEGRENADES, MELEEWEAPON, GRENADE, CROUCH, WALK, DROP, INTERACT, LASTGUN}
enum adv{DELTAFRAMES, FORWARD, BACK, LEFT, RIGHT, JUMP, SHOOT, RELOAD, ADS, GUN1,
		GUN2, MELEE, CYCLEGRENADES, MELEEWEAPON, GRENADE, CROUCH, WALK, DROP,
		INTERACT, LASTGUN}

func tick(delta: float) -> void:
	if owner_id == Lobby.selfid:
		move(delta)
#	print(viewmodel_hands.get_transform())
	if cam.is_current():
		align_hands_with_gun()
	tick_current_weapon(delta)

func align_hands_with_gun() -> void:
	viewmodel_hands.set_global_transform(current_weapon.get_skeleton().get_global_transform())

func parse_input_set(inputs: Array) -> void:
	inputdir = inputs[inputenum.MOVEMENT]
	if inputs[inputenum.JUMP]:
		jumped = true
	if inputs[inputenum.shoot]:
		shoot_current_weapon()
	if inputs[inputenum.RELOAD]:
		reload_current_weapon()
	if inputs[inputenum.ADS]:
		ADS_current_weapon()
	if inputs[inputenum.GUN1]:
		switch_weapons(PRIMARY)
	if inputs[inputenum.GUN2]:
		switch_weapons(SECONDARY)
	if inputs[inputenum.MELEE]:
		pass
	if inputs[inputenum.CYCLEGRENADES]:
		pass
	if inputs[inputenum.MELEEWEAPON]:
		pass
#		switch_weapons(MELEESLOT)
	if inputs[inputenum.GRENADE]:
		pass
	if inputs[inputenum.CROUCH]:
		pass
	# might not need this
	if inputs[inputenum.WALK]:
		pass
	if inputs[inputenum.DROP]:
		pass
	if inputs[inputenum.INTERACT]:
		pass
	if inputs[inputenum.LASTGUN]:
		switch_weapons(last_weapon_idx)
	
	# maybe this should do the PlayerInterface clamp_vector2() thing for the inputdir

func parse_input_list(inputs: PoolByteArray):
	inputdir = Vector2(0,0)
	# These shooting and ADSing vars are here, and it's to check whether or not
	# the inputs were recently input/released... I might switch this to using the
	# "set of bools" array system in the InputList.gd... also, if clear_inputs()
	# in the local player script is used, then the whole point of these vars is
	# fuckin moot, since you wouldnt be able to shoot/jump more than once with
	# that system
	var shooting: bool = false
	var ADSing: bool = false
	var inputtingwalk: bool = false
	var inputtingcrouch: bool = false
	var inputtingjump: bool = false
	for input in inputs:
		match input:
			FORWARD:
				inputdir.x += 1
			BACK:
				inputdir.x -= 1
			LEFT:
				inputdir.y -= 1
			RIGHT:
				inputdir.y += 1
			JUMP:
				inputtingjump = true
			SHOOT:
				shooting = true
			RELOAD:
				reload_current_weapon()
			ADS:
				ADSing = true
			GUN1:
				switch_weapons(PRIMARY)
			GUN2:
				switch_weapons(SECONDARY)
			MELEE:
				pass
			CYCLEGRENADES:
				pass
			MELEEWEAPON:
				pass
#				switch_weapons(MELEESLOT)
			GRENADE:
				pass
#				switch_weapons(GRENADES)
			CROUCH:
				inputtingcrouch = true
			WALK:
				inputtingwalk = true
			DROP:
				pass
			INTERACT:
				pass
			LASTGUN:
				switch_weapons(last_weapon_idx)
	if shooting:
		shoot_current_weapon()
	else:
		# this is hacky and dumb but it works fine
		current_weapon.releasedfire = true
	if ADSing:
		ADS_current_weapon()
	else:
		leave_ADS_current_weapon()
	walking = true_if_true(inputtingwalk)
	crouching = true_if_true(inputtingcrouch)
	jumped = true_if_true(inputtingjump)

func parse_advanced_inputlist(inputs: PoolByteArray) -> void:
	inputdir = Vector2(float(inputs[adv.FORWARD] - inputs[adv.BACK])/inputs[adv.DELTAFRAMES],
						float(inputs[adv.RIGHT] - inputs[adv.LEFT])/inputs[adv.DELTAFRAMES])
	if inputs[adv.JUMP] > 0:
		jumped = true
	else:
		jumped = false
	if inputs[adv.SHOOT] > 0:
		shoot_current_weapon()
	if inputs[adv.RELOAD] > 0:
		reload_current_weapon()
	if inputs[adv.ADS] > 0:
		ADS_current_weapon()
	if inputs[adv.GUN1] > 0:
		switch_weapons(PRIMARY)
	if inputs[adv.GUN2] > 0:
		switch_weapons(SECONDARY)
	if inputs[adv.MELEE] > 0:
		pass
	if inputs[adv.CYCLEGRENADES] > 0:
		pass
	if inputs[adv.MELEEWEAPON] > 0:
		pass
#		switch_weapons(MELEESLOT)
	if inputs[adv.GRENADE] > 0:
		pass
	if inputs[adv.CROUCH] > 0:
		pass
	# might not need this
	if inputs[adv.WALK] > 0:
		pass
	if inputs[adv.DROP] > 0:
		pass
	if inputs[adv.INTERACT] > 0:
		pass
	if inputs[adv.LASTGUN] > 0:
		pass

func true_if_true(this_bool: bool) -> bool:
	return true if this_bool else false

#	inputdir = Vector2(0,0)
#	# These shooting and ADSing vars are here, and it's to check whether or not
#	# the inputs were recently input/released... I might switch this to using the
#	# "set of bools" array system in the InputList.gd... also, if clear_inputs()
#	# in the local player script is used, then the whole point of these vars is
#	# fuckin moot, since you wouldnt be able to shoot/jump more than once with
#	# that system
#	var shooting: bool = false
#	var ADSing: bool = false
#	if inputs[FORWARD] > 0:
#		inputdir.x += 1
#	if inputs[BACK] > 0:
#		inputdir.x -= 1
#	if inputs[LEFT] > 0:
#		inputdir.y -= 1
#	if inputs[RIGHT] > 0:
#		inputdir.y += 1
#	if inputs[JUMP] > 0:
#		jumped = true
#	if inputs[SHOOT] > 0:
#		shooting = true
#	if inputs[RELOAD] > 0:
#		reload_current_weapon()
#	if inputs[ADS] > 0:
#		ADSing = true
#	if inputs[GUN1] > 0:
#		switch_weapons(PRIMARY)
#	if inputs[GUN2] > 0:
#		switch_weapons(SECONDARY)
#	if inputs[MELEE] > 0:
#		pass
#	if inputs[CYCLEGRENADES] > 0:
#		pass
#	if inputs[MELEEWEAPON] > 0:
#		pass
##				switch_weapons(MELEESLOT)
#	if inputs[GRENADES] > 0:
#		pass
##				switch_weapons(GRENADES)
#	if inputs[CROUCH] > 0:
#		crouching = true
#	if inputs[WALK] > 0:
#		walking = true
#	if inputs[DROP] > 0:
#		pass
#	if inputs[INTERACT] > 0:
#		pass
#	if inputs[LASTGUN] > 0:
#		switch_weapons(current_weapon_idx)
#	if shooting:
#		shoot_current_weapon()
#	if ADSing:
#		ADS_current_weapon()
#	else:
#		leave_ADS_current_weapon()

func parse_inputdir(aim: Basis):
	if inputdir.x > 0:
		direction -= aim.z
	elif inputdir.x < 0:
		direction += aim.z
	if inputdir.y > 0:
		direction += aim.x
	elif inputdir.y < 0:
		direction -= aim.x

# maybe add a this_inputdir in case theres spaghetti code and the server/client
# wind up needing to do calculations based on a player controller's variables
func calculate_speed() -> float:
	# if the player is walking backwards, reduce their speed accordingly
	if inputdir.x < 0:
		return maxwsp * back_relative * this_crouch_factor * this_walk_factor
		# if the player is moving right/left and is NOT moving forward, reduce their speed
		
		# maybe turn this into if inputdir.y.abs() > inputdir.x
	elif inputdir.y != 0 and inputdir.x < 0.5:
		return maxwsp * side_relative * this_crouch_factor * this_walk_factor
	else:
		# if the player is moving forward, let them move forward at their maximum speed
		return maxwsp * this_crouch_factor * this_walk_factor

func calculate_acceleration_floor(temp_vel: Vector3) -> float:
	if direction.dot(temp_vel) > 0:
		return float(acceleration)
	else:
		return float(decceleration)

func calculate_acceleration_air(temp_vel: Vector3) -> float:
	if direction.dot(temp_vel) > 0:
		return float(air_acceleration)
	else:
		return float(air_decceleration)

func tick_walk_factor() -> void:
	if walking:
		this_walk_factor = walk_factor
	else:
		this_walk_factor = 1.0

func tick_crouch_factor() -> void:
	if crouching:
		this_crouch_factor = crouch_factor
	else:
		this_crouch_factor = 1.0

func move(delta: float) -> void:
	direction = Vector3()
	parse_inputdir(head.get_global_transform().basis)
	direction.y = 0
	direction = direction.normalized()
	tick_walk_factor()
	tick_crouch_factor()
	var speed = calculate_speed()
	var temp_vel:= velocity
	# this might be redundant
	temp_vel.y = 0
	var target: Vector3 = direction * speed
	var temp_accel: float
	
	var snap: Vector3
	if is_on_floor():
		if jumped:
			snap = Vector3.ZERO
			velocity.y += jump_strength
			jumped = false
		else:
			snap = Vector3.DOWN
		temp_accel = calculate_acceleration_floor(temp_vel)
	else:
		temp_accel = calculate_acceleration_air(temp_vel)
	
	velocity.y -= grav * delta
	
	temp_vel = temp_vel.linear_interpolate(target, temp_accel * delta)
	velocity.x = temp_vel.x
	velocity.z = temp_vel.z
	
	# stops on slopes
	if direction.dot(velocity) == 0:
		velocity.x = smaller_than_clamp(velocity.x, 0.25)
		velocity.z = smaller_than_clamp(velocity.z, 0.25)
	
	var moving = move_and_slide_with_snap(velocity, snap, Vector3.UP, true, 4, FLOOR_MAX_ANGLE)
	
	if is_on_wall():
		velocity = moving
	else:
		velocity.y = moving.y

func smaller_than_clamp(this_vel: float, this_clamp: float) -> float:
	if abs(this_vel) < this_clamp:
		return 0.0
	else:
		return this_vel

func aim(direction: Vector2, player_influenced:= true) -> void:
	rotation_degrees.y -= direction.x
	head.rotation_degrees.x = clamp_vertical_aim(head.rotation_degrees.x -direction.y)
	current_weapon.set_weapon_tilt(direction.x)

# careful with this!
func set_aim(direction: Vector2) -> void:
	rotation_degrees.y = direction.x
	head.rotation_degrees.x = direction.y

static func clamp_vertical_aim(value: float) -> float:
	return clamp(value, -90, 90)

func set_primary(to_weapon: BaseWeapon) -> void:
	weapons[PRIMARY] = to_weapon

func set_secondary(to_weapon: BaseWeapon) -> void:
	weapons[SECONDARY] = to_weapon

func give_weapon(weapon: BaseWeapon, inventory_position: int) -> void:
	weapon.spawn(head)
	weapons[inventory_position] = weapon
	if current_weapon_idx != inventory_position:
		weapon.hide()

func spawn(start_transform: Transform, gun_1: BaseWeapon, gun_2: BaseWeapon) -> void:
	Lobby.my_client.map.add_child(self)
	set_global_transform(start_transform)
	setup_weapons(gun_1, gun_2)

func setup_weapons(gun_1: BaseWeapon, gun_2: BaseWeapon) -> void:
	give_weapon(gun_1, 0)
	give_weapon(gun_2, 1)
	# this might not work
#	switch_weapons(0)
	change_current_weapon(0)
	if weapons[1]:
		change_last_weapon(1)
	elif weapons[2]:
		change_last_weapon(2)
	else:
		print(" asdf klj;afsd;kjlafsdkjl;afdskl;jf;l jkasf d check the playercontroller what the fuck")
	visually_switch_weapons()

func go_third_person() -> void:
	viewmodel_hands.hide()
	current_weapon.hide()
	third_person_model.show()
	beak.show()

func go_first_person() -> void:
	viewmodel_hands.show()
	current_weapon.show()
	third_person_model.hide()
	beak.hide()
	cam.set_current(true)

func switch_weapons(to: int) -> void:
	if !weapons[to] or to == current_weapon_idx:
		return
	else:
		prep_leaving_current_weapon()
		change_last_weapon_to_current()
		change_current_weapon(to)
		visually_switch_weapons()
		draw_current_weapon()

# maybe rename this to freeze_current_weapon_funcs
func prep_leaving_current_weapon() -> void:
	if current_weapon.zoomed:
		current_weapon.force_leave_ADS_local()
	if current_weapon.loading:
		current_weapon.cancel_reload()
	if current_weapon.get_current_draw_time() < current_weapon.draw_time:
		current_weapon.cancel_draw()

# this function is intended to be called within the switch_weapons function,
# where last_weapon and current_weapon have already been correctly assigned
func visually_switch_weapons():
	bind_viewmodel_skeleton_to_current_weapon()
	last_weapon.hide()
	current_weapon.show()

# note about the next couple functions: changing it from weapons[current_weapon] etc
# to current_weapon/last_weapon as direct references means that switching weapons
# now has 2 extra assigns for the sake of readability. basically, the optimal way
# to do things is exclusively with the old way. but I'm not gonna do that, since
# it makes things easier to write. maybe something to change in the future, once
# things are better figured out.

# WARNING: this function has no checks/protections against setting the current weapon
# to an incorrect position, since it's just meant to be called from other functions
func change_current_weapon(to: int) -> void:
	current_weapon_idx = to
	# i couldve done it as weapons[current_weapon_idx], but it really dont matter
	current_weapon = weapons[to]

func change_last_weapon(to: int) -> void:
	last_weapon_idx = to
	last_weapon = weapons[to]

# this is high key redundant and could be done with change_last_weapon(current_weapon_idx)
func change_last_weapon_to_current() -> void:
	change_last_weapon(current_weapon_idx)

func bind_viewmodel_skeleton_to_weapon(weapon: BaseWeapon) -> void:
	viewmodel_hands.set_skin(preloader.get_resource(weapon.skeleton_skin))
	viewmodel_hands.set_skeleton_path(NodePath("../%s/%s" % [weapon.get_name(), weapon.skeleton_path]))

func bind_viewmodel_skeleton_to_weapon_by_id(weapon: int) -> void:
	bind_viewmodel_skeleton_to_weapon(weapons[weapon])

func bind_viewmodel_skeleton_to_current_weapon() -> void:
	bind_viewmodel_skeleton_to_weapon(current_weapon)

func bind_viewmodel_skeleton_to_current_weapon_int() -> void:
	bind_viewmodel_skeleton_to_weapon_by_id(current_weapon_idx)


# these were originally current_weapon.draw_weapon() and such, but now they're
# funcref's

# then there was this bit where it was something like drawfunc.call_funcv([current_weapon])

# NOTE: USE THE SECOND VERSION IF THE FIRST VERSION IS BROKEN. theres a chance that
# the funcref doesn't get updated on switching weapons, since the reference might just
# compile with the current_weapon's current assigned value, and not just a reference
# to a dynamically changing function. idk

# DRAW WEAPON STUFF
# -----------------------------------------------------------------------------
func draw_current_weapon() -> void:
	drawfunc.call_func()

func serverdraw() -> void:
	current_weapon.draw_weapon_server()

func localdraw() -> void:
	current_weapon.draw_weapon_local()

func remotedraw() -> void:
	current_weapon.draw_weapon_remote()

# TICK WEAPON STUFF
# -----------------------------------------------------------------------------
func tick_current_weapon(delta: float) -> void:
	guntickfunc.call_func(delta)

func serverguntick(delta: float) -> void:
	current_weapon.tick_weapon_server(delta)

func localguntick(delta: float) -> void:
	current_weapon.tick_weapon_local(delta)

func remoteguntick(delta: float) -> void:
	current_weapon.tick_weapon_remote(delta)

# SHOOT WEAPON STUFF
# -----------------------------------------------------------------------------
func shoot_current_weapon() -> void:
	shootfunc.call_func()

func servershoot() -> void:
	# maybe rename this to server_shoot or something
	current_weapon.shoot_server()

func localshoot() -> void:
	# maybe rename this to local_shoot or something
	if current_weapon.shoot_local():
		emit_signal("ammo_updated")

# this might not even wind up being used since I want to do shooting thru actions,
# right? lol
func remoteshoot() -> void:
	current_weapon.shoot_remote()

# RELOADING STUFF
# -----------------------------------------------------------------------------
func reload_current_weapon() -> void:
	reloadfunc.call_func()

func serverreload() -> void:
	current_weapon.reload_server()

func localreload() -> void:
	current_weapon.reload_local()

func remotereload() -> void:
	current_weapon.reload_remote()

# ADS STUFF
# -----------------------------------------------------------------------------
func ADS_current_weapon() -> void:
	ADSfunc.call_func()

func serverADS() -> void:
	current_weapon.ADS_server()

func localADS() -> void:
	current_weapon.ADS_local()

func remoteADS() -> void:
	current_weapon.ADS_remote()

# LEAVE ADS STUFF
# -----------------------------------------------------------------------------
func leave_ADS_current_weapon() -> void:
	leaveADSfunc.call_func()

func serverleaveADS() -> void:
	current_weapon.leave_ADS_server()

func localleaveADS() -> void:
	current_weapon.leave_ADS_local()

func remoteleaveADS() -> void:
	current_weapon.leave_ADS_remote()

# DROP WEAPON STUFF
# -----------------------------------------------------------------------------
func drop_current_weapon() -> void:
	pass

# maybe this is a bit ambiguous
func serverdrop() -> void:
	pass

func localdrop() -> void:
	pass

func remotedrop() -> void:
	pass

# INTERACT STUFF
# -----------------------------------------------------------------------------
func serverinteract() -> void:
	pass

func localinteract() -> void:
	pass

func remoteinteract() -> void:
	pass

# this could reasonably be done by just returning an array, without using the
# 'info' var, but it looks nicer, and is quicker to add stuff with the .xyz stuff
func generate_info() -> Dictionary:
	var info: Dictionary
	info.owner_id = owner_id
	info.position = global_transform.origin
	# this is kinda dumb
	info.transform = global_transform
	info.direction = direction
	info.velocity = velocity
	info.aim_angle = get_aim_angle()
	info.hp = hp
	info.onfloor = is_on_floor()
#	info.inputs = 
	info.dead = dead
	info.weapons = serialize_weapons()
	info.crouching = crouching
	info.current_weapon_idx = current_weapon_idx
	info.team = team
	return info

# just semantics
func serialize() -> Dictionary:
	return generate_info()

func generate_info_full() -> Dictionary:
	var info: Dictionary = generate_info()
	info.gun_1 = serialize_weapon(weapons[PRIMARY])
	info.gun_2 = serialize_weapon(weapons[SECONDARY])
	info.meleeweapon = serialize_weapon(weapons[MELEESLOT])
	# maybe i did this wrong
	info.grenades = serialize_weapon(weapons[GRENADES])
	return info

func serialize_weapon(weapon: BaseWeapon) -> Dictionary:
	if weapon:
		return weapon.serialize()
	else:
		return {}

func serialize_weapons() -> Array:
	return [serialize_weapon(weapons[0]),
	serialize_weapon(weapons[1])]

#func generate_info(id: int) -> Dictionary:
#	var data := {}
#	var this_player= playerlist[id]
#	data.id = id
#	data.position = this_player.get_global_transform_origin()
#	data.direction = this_player.get_direction()
#	data.velocity = this_player.get_velocity()
#	data.aim_angle = this_player.get_aim_angle()
#	data.hp = this_player.get_hp()
#	data.onfloor = this_player.is_on_floor()
#	data.dead = this_player.get_dead()
#	data.inputs = this_player.get_inputs()
#	data.weapons = this_player.get_weapons()
#	data.crouching = this_player.get_crouching()
#	data.current_weapon = this_player.get_current_weapon()
#	data.inputinfo = this_player.get_input_info()
#	return data
#	#vars not already implemented
#	#data.team = this_player.team
#	#data.username = this_player.myname

func interpolate_position(from: Vector3, to: Vector3) -> void:
#	var inbetween: Vector3 = to - from
	global_transform.origin = to + (to - from) * Engine.get_physics_interpolation_fraction()

func return_interpolate_position(from: Vector3, to: Vector3) -> Vector3:
	global_transform.origin = to + (to - from) * Engine.get_physics_interpolation_fraction()
	return global_transform.origin
