extends Spatial
class_name BaseWeapon

export(float, 0, 10) var fire_rate = 0.0
export(int, 0, 500) var magsize = 0
export(float, 0, 10) var reload_speed = 0.0
export(float, 0, 10) var chamber_time = 0.0
export(int, 0, 500) var dmg = 0
export(int, 0, 100) var hs_mult = 2
enum {AUTO, SINGLE, PUMPBOLT}
export(int, "Automatic", "Single", "Pump/Bolt Action") var fire_type = 0
export(float, 0, 100) var vrecoil = 0.0
export(float, -100, 100) var hrecoil = 0.0
export(float, 0, 100) var aim_vrecoil = 0.0
export(float, -100, 100) var aim_hrecoil = 0.0
export(float, -100, 100) var hrecoil_freq = 5.0
export(float, -30, 100) var vrecoil_apex = 0
export(float, 0, 10) var max_vrecoil = 0.0
export(float, 0, 10) var curve_width = 0.0


export(float, 0, 1) var firing_stability = 1.0
export(float, 0, 1) var movement_stability = 1.0
export(float, 0, 1) var aim_firing_stability = 1.0
export(float, 0, 1) var aim_movement_stability = 1.0

# maybe worth splitting this up so that movement tilting and aiming tilting are
# 2 different vars

# tilt factor sets how much the weapon tilts, including by a negative value, so
# that certain weapons can tilt differently
export(float, -2, 2) var tilt_factor = 1.0

onready var fire_sway_factor = 1 - firing_stability
onready var move_sway_factor = 1 - movement_stability
onready var aim_fire_factor = 1 - aim_firing_stability
onready var aim_move_factor = 1 - aim_movement_stability

export(Curve) var sway_curve
export(Curve) var recoil_curve
export(Curve) var shot_curve

enum {FIRE, THROWGRENADE, SPAWN, KILL, DAMAGE, MAKESOUND}

# determines the "weight" of the gun. scalar value from 0 to 1. the player script yoinks this variable,
# and subtracts it from 1 to determine how fast the player should move while holding the gun
export(float, 0, 1) var weight = 0.0
# replaces the weight value in the player script when the player is aiming down the sights
export(float, 0, 1) var aim_weight = 0.0

export(float, 0, 2) var draw_time = 0.0


export(int, "Pistol", "Submachine Gun", "Shotgun", "Assault Rifle", "DMR", "Sniper Rifle", "LMG") var section
export(int, 0, 10000) var price = 0

# modifiable cosmetic variables that don't impact gameplay
export(int, "9mm", "5.56", "7.62", ".300", ".45", ".50", "12 gauge", "4.6x30") var caliber

# relevant nodes that the weapon will need to reference
# V V V V V V V V V V V V V

# when editing player script, change the kinematicbody thing to playercontroller
# for debugging purposes of autofill and ide stuff. but for some reason when
# this gets parsed the playercontroller script wont load, (probably because the
# baseweapon script gets first called/loaded when the playercontroller script
# is getting loaded), so this is the next best thing 
onready var player: KinematicBody = $"../../"
onready var maxwsp: float = player.maxwsp
# i think this is broken lol
onready var camera: Camera = $"../World Camera"
onready var firetimer: Timer = $firetimer
onready var reloadtimer: Timer = $reloadtimer
onready var drawtimer: Timer = $drawtimer
onready var chambertimer: Timer = $chambertimer
onready var rotationalparent: Position3D = $"Rotational Parent"
export var sound = preload("res://Assets/Audio/SFX/Gunshots/test sound 2 16-bit.wav")
export(String, "Dropped Weapon", "Dropped M4", "Dropped AK", "Dropped 1911") var dropped_counterpart: String = "Dropped Weapon"
export(String, "M4 Skin", "1911 Skin", "AK Skin", "Glock Skin") var skeleton_skin: String = "M4 Skin"
export(NodePath) var skeleton_path
onready var ADS_offset_reference: Position3D = $"Rotational Parent/ADS Shot Offset Reference"

export(float, 0.005, 1) var viewmodel_scale = 0.01
export(float, 0.01, 5) var third_person_scale = 0.029

# depreciated
#onready var viewmodel_scale: Vector3 = get_node(skeleton_path).scale

# references that scripts will access to change gun orientation/rotation
onready var tree: AnimationTree = $tree
onready var state: AnimationNodeStateMachinePlayback = tree.get("parameters/Weapon State/playback")
var tilt: float = 0.0
var direction: Vector2 = Vector2(0,0)

var current_ammo: int
# maybe one day turn this into an int that increases/decreases
var canshoot := true
var shot := false
var loading := false
var current_recoil := 0.0
var recovering := false
var camreset: float
var recoverytime := 0
var zoomed := false

# transient variables that are the same as their counterparts without the "this_" prefix, when not zoomed in,
# and are updated to the ADS_ version when the player zooms in
onready var this_vrecoil = vrecoil
onready var this_hrecoil = hrecoil
onready var this_weight = weight
onready var this_move_factor = move_sway_factor
onready var this_fire_factor = fire_sway_factor

#single fire and pump/bolt action-exclusive variable that checks if the player has released the fire button
var releasedfire := true

#pump/bolt action-exclusive variable that checks if the bolt/pump has been cycled
var cycled: bool = true

var sway: Vector2 = Vector2(0,0)

var actual_weapon_sway: Vector2 = Vector2(0,0)

var vertical_sway_factor: float = 0.0

#clamped delta var so that recoil never goes too crazy
var clelta: float = 0.01

#constant to quickly get 1/60 as a float with maximum floating point precision
const sixty: float = 0.016667

#transient variable used to determine how much the gun viewmodel is bouncing
# from recoil
var shotfactor := Vector2(0,0)

#transient variable. how much the gun should be swaying based on how fast its
# going relative to its max speed, then multiplied by its current movement
# swaying factor
var swayfactor: float = 0.0

var current_vrecoil: float = 0.0

var current_hrecoil: float = 0.0

var shooting_sway_offset: Vector2 = Vector2(0,0)

var first_pickup:= true

# this whole manual shit is fucking dumb. FIX IT LMFAO
var manual: bool = false

signal auto_reload
signal ADS_confirmed
signal leave_ADS_confirmed
signal shot_confirmed
# this is named poorly
signal ammo_reloaded
signal weapon_drawn

func _ready():
	if !tree.is_active():
		tree.set_active(true)
	# FIX THIS
	if !manual:
		firetimer.set_wait_time(fire_rate)
		reloadtimer.set_wait_time(reload_speed)
		drawtimer.set_wait_time(draw_time)
	# this is fine
#	find_ADS_offset_reference()
	connect("auto_reload", player, "reload_current_weapon")
	# deferring this is hacky and dumb but fuck u lol
	call_deferred("setup_HUD_connections")
	set_process(false)

func setup_HUD_connections() -> void:
	if player.owner_id == Lobby.selfid:
		connect("shot_confirmed", Lobby.my_client.HUD, "on_player_fired")
		connect("ADS_confirmed", Lobby.my_client.HUD, "on_player_ADS")
		connect("leave_ADS_confirmed", Lobby.my_client.HUD, "on_player_leave_ADS")
		connect("ammo_reloaded", Lobby.my_client.HUD, "on_player_reloaded")
		connect("weapon_drawn", Lobby.my_client.HUD, "on_new_weapon_drawn")

# this was a great idea but unless we get rid of shootingdelta from the inputlist
# thingy, then this isnt gonna be used
#func connect_local_shooting_to_record_interpolation_fraction() -> void:
#	if Lobby.selfid:
#		connect("shot_confirmed", Lobby.playerlist[Lobby.selfid], "record_shot")

# might crash the game
#func find_ADS_offset_reference() -> void:
#	ADS_shot_offset_reference = $"Rotational Parent".get_node_or_null("ADS Shot Offset Reference")

func spawn(parent: Spatial, var ammo:= magsize, start_cycled := true,
			start_loading:= false, start_shot_timer:= fire_rate,
			start_reload_timer:= reload_speed, start_draw_timer:= draw_time,
			start_chamber_timer:= chamber_time):
	# FIX THIS MANUAL BULLSHIT LMFAO
	manual = true
	parent.add_child(self)
	current_ammo = ammo
	cycled = start_cycled
	loading = start_loading
	set_timers(start_shot_timer, start_reload_timer, start_draw_timer, start_chamber_timer)
	# um so these dont do animations or anything cuz im lazy. FIX THIS SHIT
	if firetimer.wait_time < fire_rate:
		firetimer.start()
	if reloadtimer.wait_time < reload_speed:
		calculate_reload()
	if drawtimer.wait_time < draw_time:
		calculate_draw_weapon()

func set_timers(this_shot_time: float, this_reload_time: float, this_draw_time: float, this_chamber_time: float) -> void:
	firetimer.set_wait_time(this_shot_time)
	reloadtimer.set_wait_time(this_reload_time)
	drawtimer.set_wait_time(this_draw_time)
	chambertimer.set_wait_time(this_chamber_time)

func weapon_is_empty() -> bool:
	return true if current_ammo < 1 else false

func try_reload_if_empty() -> void:
	if weapon_is_empty():
		if not loading:
			emit_signal("auto_reload")

static func vertical_recoil_formula(offset: float, recoil_value: float, maximum: float, apex_offset: float, this_curve_width: float) -> float:
	return recoil_value * (maximum * exp( -0.1 * ( pow(offset - apex_offset, 2) / this_curve_width ) ) )

static func horizontal_recoil_formula(offset: float, recoil_value: float, frequency: float) -> float:
	return recoil_value * sin( (PI * offset) / (2 * frequency) )

static func apply_visual_appeal(this_fire_rate: float, time_offset: float, frame_delta: float) -> float:
	return pow(3, 1-((this_fire_rate - time_offset) * 30)) * frame_delta

func tick_vertical_recoil() -> void:
	current_vrecoil = vertical_recoil_formula(current_recoil, this_vrecoil, max_vrecoil, vrecoil_apex, curve_width) * apply_visual_appeal(fire_rate, firetimer.time_left, clelta)

func tick_horizontal_recoil() -> void:
	current_hrecoil = horizontal_recoil_formula(current_recoil, this_hrecoil, hrecoil_freq) * apply_visual_appeal(fire_rate, firetimer.time_left, clelta)

func tick_recoil_and_offsets() -> void:
	tick_recoil()
	calculate_both_shooting_sway_offsets()
	if weapon_shooting_is_affecting_sway():
		recover_shotfactor()
	else:
		add_shooting_sway_offset_to_shotfactor()

func tick_recoil_and_offsets_recovery() -> void:
	if weapon_has_recoil():
		tick_current_recoil_reduction()
	if shotfactor_is_not_reset():
		recover_shotfactor()

func tick_full_recoil_with_offsets_and_recovery() -> void:
	if shot:
		tick_recoil_and_offsets()
		# yes, this is correct, player aim is for some dumbass rotational reason
		# done using vertical,horizontal instead of horizontal,vertical
		player.aim(Vector2(-current_hrecoil, -current_vrecoil), false)
	else:
		tick_recoil_and_offsets_recovery()

func tick_local_recovery() -> void:
	if recovering:
		if camera_has_not_recovered():
			print("gaming")
			tick_recoil_recovery()
		else:
			recoverytime = 0
		stop_recovering_if_done()

func camera_has_not_recovered() -> bool:
	return true if camera.get_rotation_degrees().x > camreset else false

func stop_recovering_if_done() -> void:
	if recoverytime == 0:
		recovering = false

func shotfactor_is_not_reset() -> bool:
	return true if shotfactor != Vector2(0,0) else false

func add_shooting_sway_offset_to_shotfactor() -> void:
	shotfactor += shooting_sway_offset

func weapon_shooting_is_affecting_sway() -> bool:
	return true if shooting_sway_offset == Vector2(0,0) else false

func tick_recoil() -> void:
	tick_vertical_recoil()
	tick_horizontal_recoil()

func tick_recoil_recovery() -> void:
	tick_camera_recovery()
	tick_recoverytime_reduction()

func tick_camera_recovery() -> void:
	player.aim(Vector2(0, (1 + sqrt(recoverytime)) * vrecoil * clelta), false)

func tick_recoverytime_reduction() -> void:
	recoverytime = clamp(recoverytime - clelta, 0, 20)

func tick_current_recoil_reduction() -> void:
	current_recoil = clamp(current_recoil - (clelta / fire_rate), 0, magsize)

func tick_weapon_sway(delta: float, velocity: Vector3, direction: Vector3) -> void:
	# originally this function was going to use in place of combine_horizontal_values,
	# 2 separate functions that were going to call that function, but it really
	# just turned out to be this bloated bit of semantics that didnt really do anything,
	# so now the combine_horizontal_values() stuff is there. In short, the 2 values
	# are the combined horizontal direction and velocity of the player character
	if combine_horizontal_values(direction) > 0:
		tick_horizontal_sway_value(delta, MAXHORIZONTALSWAYVALUE)
	else:
		sway.x = move_toward(sway.x, closest_centered_horizontal_sway_value(), delta)
	tick_swayfactor(combine_horizontal_values(velocity))
	tick_vertical_sway(delta, velocity.y)
#	print("sway:")
#	print(sway)
	# updates the sway value because fuck you i dont feel like going as deep as
	# I did with the wepaon recoil bits
	generate_sway()
	# if the script calls the player here, then where the fuck is the point in
	# passing the velocity and direction as args, and not just... bruh
	set_weapon_tilt(player.inputdir.y + actual_weapon_sway.x)
	sway_and_tilt_weapon()

func tick_weapon_tilt(delta: float) -> void:
	tilt = lerp(tilt, 0, 5*delta)

func set_weapon_tilt(amount: float) -> void:
	tilt -= (amount/120) * move_sway_factor * tilt_factor

func sway_and_tilt_weapon() -> void:
	rotationalparent.set_rotation(Vector3(actual_weapon_sway.y, actual_weapon_sway.x - deg2rad(180), tilt))

func generate_sway() -> void:
	var sinsway: float = generate_sin_sway()
	actual_weapon_sway = Vector2(sinsway + shotfactor.x, generate_vertical_sway_from_horizontal_movement(sinsway) + sway.y - shotfactor.y)

static func generate_vertical_sway_from_horizontal_movement(amount: float) -> float:
	return pow(amount, 2) / 4

# sways but just gets the player's vars to fill in, to just shorten the semantics,
# basically
func tick_sway_from_owning_player(delta: float) -> void:
	tick_weapon_sway(delta, player.velocity, player.direction)

#func get_combined_horizontal_direction(direction: Vector3) -> float:
#	return combine_horizontal_values(direction)
#
#func get_combined_horizontal_velocity(velocity: Vector3) -> float:
#	return combine_horizontal_values(velocity)

func closest_centered_horizontal_sway_value() -> float:
	return round(sway.x)

func tick_horizontal_sway_value(delta: float, towards: float) -> void:
	if sway.x == MAXHORIZONTALSWAYVALUE:
		sway.x = 0.0
	else:
		#													this is insanely stupid
		sway.x = move_toward(sway.x, towards, delta * move_toward(player.this_walk_factor, 1, 0.25))

static func combine_horizontal_values(value: Vector3) -> float:
	return abs(value.x) + abs(value.z)

func tick_vertical_sway(delta: float, vertical_velocity: float) -> void:
	# this bit of passing the vertical velocity and turning it to 0 if the player
	# is on the floor is kinda hacky
	if player_is_on_floor():
		vertical_velocity = 0
	else:
		vertical_velocity = clamp(vertical_velocity, -1, 1)
	set_vertical_sway(delta, vertical_velocity)

# this is only intended to be called from the tick_vertical_sway function, so the
# function assumes that vertical_Velocity has already been clamped
func set_vertical_sway(delta: float, vertical_velocity: float) -> void:
	sway.y = move_toward(sway.y, vertical_velocity, 1.2 * delta)

func player_is_on_floor() -> bool:
	return true if player.is_on_floor() else false

func tick_swayfactor(velocity: float) -> void:
	swayfactor = (velocity / ( (1 - this_weight) * maxwsp )) * this_move_factor

func generate_sin_sway() -> float:
	return swayfactor * -sin(2*PI*sway.x)

# these 2 functions are the same but one of them checks and doesnt crash if the
# "proportion" var is 0
# //////////////////////////////////////////////////////////////////////////////
static func calculate_shot_shooting_sway_offset(offset: float, proportion: float, fire_factor: float, sway_factor: float) -> float:
	return clamp((offset / proportion) * (fire_factor + sway_factor), -1, 1)

static func calculate_shot_shooting_sway_offset_0_safe(offset: float, proportion: float, fire_factor: float, sway_factor: float) -> float:
	if proportion == 0:
		return 0.0
	else:
		return clamp((offset / proportion) * (fire_factor + sway_factor), -1, 1)
# //////////////////////////////////////////////////////////////////////////////

func calculate_vertical_shooting_sway_offset() -> float:
	return calculate_shot_shooting_sway_offset(current_vrecoil, this_vrecoil * max_vrecoil, this_fire_factor, swayfactor)

func calculate_horizontal_shooting_sway_offset() -> float:
	return calculate_shot_shooting_sway_offset_0_safe(current_hrecoil, this_hrecoil, this_fire_factor, swayfactor)

func calculate_both_shooting_sway_offsets() -> void:
	shooting_sway_offset = Vector2(calculate_horizontal_shooting_sway_offset(), calculate_vertical_shooting_sway_offset())

static func move_toward_shotfactor(this_shotfactor_value: float, delta: float) -> float:
	return move_toward(this_shotfactor_value, 0, 1.5 * delta)

# more or less just a macro for recovering since its called twice under certain
# conditions being met
func recover_shotfactor():
	shotfactor = Vector2(move_toward_shotfactor(shotfactor.x, clelta), move_toward_shotfactor(shotfactor.y, clelta))

func weapon_has_recoil() -> bool:
	return true if current_recoil != 0 else false

func tick_weapon_local(delta: float) -> void:
	clelta(delta)
	tick_weapon()
	tick_local_recovery()
	# this should probably be optimized. also, it's outside the tick_weapon
	# function because this code is still stupid! FUCK!
	tick_sway_from_owning_player(delta)
	tick_weapon_tilt(delta)

func tick_weapon_server(delta: float) -> void:
	clelta(delta)
	tick_weapon()
	# this should probably be optimized. also, it's outside the tick_weapon
	# function because this code is still stupid! FUCK!
	tick_sway_from_owning_player(delta)

func tick_weapon_remote(delta: float) -> void:
	tick_weapon_server(delta)

func tick_weapon() -> void:
	# maybe dont do this remotely
	try_reload_if_empty()
	tick_full_recoil_with_offsets_and_recovery()

func _process(delta: float):
	pass

func shoot() -> bool:
	if if_gun_can_shoot():
		calculate_shot()
		firetimer.start()
		return true
	else:
		return false

func if_gun_can_shoot() -> bool:
	if fire_type == AUTO || releasedfire == true:
		if canshoot:
			return true
		else:
			return false
	else:
		return false

func calculate_shot() -> void:
	current_ammo -= 1
	canshoot = false
	# might be pointless unless it's bolt/pump action
	cycled = false
	if fire_type != 0:
		releasedfire = false
	current_recoil += 1
	shot = true
	recovering = false
	#if the gun isn't recovering, set the gun's resting point to it's current location, before any recoil
	# takes place ... THIS MAY BE REDUNDANT, if the camreset keeps being set in the _aim function
	if recoverytime == 0:
		camreset = camera.get_rotation_degrees().y
	#adds recovery time by however long it takes to shoot the gun. might be worth changing for single fire
	# and bolt/pump action guns
	recoverytime+=fire_rate
	print(current_ammo)
	emit_signal("shot_confirmed")

func play_shot_sound() -> void:
	Audio_Manager.play(self, sound, 80, 6,1 + 0.01 * current_vrecoil + 0.01 * current_hrecoil)

func start_firing_timer() -> void:
	firetimer.start()
	# is there a reason that this should be "manually" oneshot set in code, and not
	# just always connected from the editor? 
#	timer.connect("timeout", self, "_cycled", [], CONNECT_ONESHOT)

func play_shooting_animation_fp() -> void:
	if tree["parameters/Add First Shot/active"] == true:
		tree["parameters/Add Second Shot/active"] = true
	else:
		tree["parameters/Add First Shot/active"] = true

func _cycled() -> void:
	shot = false
	recovering = true
	# might be pointless unless it's bolt/pump action
	cycled = true
	# makes sure that other circumstances aren't taking priority over this, and
	# that is's cool to let the gun shoot again.
	check_can_shoot()

# notes about displaying stuff for server, the server might wind up needing to
# calculate first person animations, if that's how some of the aiming directions
# work

func display_reload_fp() -> void:
	print("displaying reload")
	if current_ammo > 0:
		state.travel("Tactical Reload")
	else:
		state.travel("Reload")

func display_reload_tp() -> void:
	pass

func reload_local() -> void:
	if calculate_reload():
		display_reload_fp()

func reload_server() -> void:
	if calculate_reload():
		display_reload_tp()

func reload_remote() -> void:
	display_reload_tp()

func calculate_reload() -> bool:
	if current_ammo < magsize and not loading and !is_drawing_weapon():
		if leave_ADS_logic():
			if get_parent().is_network_master():
				display_leave_ADS_fp()
			else:
				display_leave_ADS_tp()
		canshoot = false
		loading = true
		reloadtimer.start()
		chambertimer.start()
#		tree[blendamount] = 0
		return true
	else:
		return false

func _on_reloadtimer_timeout():
	loading = false
	canshoot = true
#	tree[blendamount] = 1

func _on_chambertimer_timeout():
	current_ammo = magsize
	# this is named poorly
	emit_signal("ammo_reloaded")

func cancel_reload():
	loading = false
	reloadtimer.stop()
	chambertimer.stop()
	if current_ammo > 0:
		canshoot = true
	print("cancelling reload")
	state.start("Rest")
#	tree[blendamount] = 1

func ADS_server() -> void:
	if ADS_logic():
		display_ADS_tp()

func ADS_local() -> void:
	if ADS_logic():
		display_ADS_fp()

func ADS_remote() -> void:
	ADS_server()

func leave_ADS_server() -> void:
	if leave_ADS_logic():
		display_leave_ADS_tp()

func leave_ADS_local() -> void:
	if leave_ADS_logic():
		display_leave_ADS_fp()

func leave_ADS_remote() -> void:
	leave_ADS_server()

func ADS_logic() -> bool:
	if not zoomed and loading == false:
		set_ADS_vars()
		emit_signal("ADS_confirmed")
		return true
	else:
		return false

func set_ADS_vars() -> void:
	zoomed = true
	this_vrecoil = aim_vrecoil
	this_hrecoil = aim_hrecoil
	this_weight = aim_weight
	this_fire_factor = aim_fire_factor
	this_move_factor = aim_move_factor

func set_hipfire_vars() -> void:
	zoomed = false
	this_vrecoil = vrecoil
	this_hrecoil = hrecoil
	this_weight = weight
	this_fire_factor = fire_sway_factor
	this_move_factor = move_sway_factor


func display_ADS_fp() -> void:
	state.travel("ADS Intro")

func display_ADS_tp() -> void:
	pass

func display_leave_ADS_fp() -> void:
	state.travel("ADS Outro")

func display_leave_ADS_tp() -> void:
	pass

func leave_ADS_logic() -> bool:
	if zoomed == true:
		set_hipfire_vars()
		emit_signal("leave_ADS_confirmed")
		return true
	else:
		return false

func force_leave_ADS_local() -> void:
	set_hipfire_vars()
	print("forcing leaving ads!")
	state.start("Rest")

const MAXHORIZONTALSWAYVALUE: float = 2.0



func drop():
	var dropped: DroppedWeapon = preloader.get_resource(dropped_counterpart).instance()
	dropped.spawn(current_ammo)
	player.get_parent().add_child(dropped)
	dropped.global_transform.origin = player.head.global_transform.origin + Vector3(0, 0.2, 0) # this needs to be changed to account for the viewing angle
	dropped.set_rotation_degrees(player.get_rotation_degrees())
	dropped.apply_central_impulse(Vector3(1,5,0))
#	parent.velocity.x + parent.cam.get_rotation_degrees
	queue_free()

func shoot_local() -> bool:
	if shoot():
		display_shot_fp()
		return true
	else:
		return false

func shoot_server():
	if shoot():
		display_shot_tp()

func shoot_remote():
	display_shot_tp()

func display_shot_fp():
	play_shot_sound()
	play_shooting_animation_fp()

func display_shot_tp():
	play_shot_sound()


func display_draw_weapon_fp():
	print("displaying weapon draw")
	if cycled != true:
		state.start("Draw and Rack Bolt")
	elif first_pickup:
		state.start("Draw First Time")
		first_pickup = false
	else:
		state.start("Draw")
#	tree[blendamount] = 0

func calculate_draw_weapon() -> void:
	canshoot = false
	drawtimer.start()

func display_draw_weapon_tp() -> void:
	pass

func draw_weapon_local() -> void:
	calculate_draw_weapon()
	# lol
#	call_deferred("display_draw_weapon_fp")
	display_draw_weapon_fp()
	emit_signal("weapon_drawn")

func draw_weapon_server() -> void:
	calculate_draw_weapon()
	display_draw_weapon_tp()

# this is redundant. but fuck you!
func draw_weapon_remote() -> void:
	display_draw_weapon_tp()

func finish_draw():
#	tree[blendamount] = 1
	check_can_shoot()

func check_can_shoot() -> void:
	if not loading and current_ammo > 0:
		canshoot = true

func get_current_draw_time() -> float:
	return drawtimer.get_time_left()

func is_drawing_weapon() -> bool:
	# if a timer is inactive it also returns 0, so this works no matter what :)
	return false if drawtimer.get_time_left() == 0 else true

func get_current_shot_time() -> float:
	return firetimer.get_time_left()

func get_current_reload_time() -> float:
	return reloadtimer.get_time_left()

func cancel_draw():
	drawtimer.stop()
	drawtimer.set_wait_time(draw_time)
	print("cancelling draw!")
	state.start("Rest")
#	tree[blendamount] = 1

# probs depreciated more or less
func check_crosshair_on_off(on_off: bool = true):
	if player.is_network_master() == false:
		return
	else:
		if on_off:
			player.crosshair.show()
		else:
			player.crosshair.hide()

func clelta(delta: float) -> void:
	clelta = clamp(delta, 0, sixty)
#	return clelta

func get_skeleton() -> Node:
	return get_node(skeleton_path)

# could totally serialize this as an array with enum's instead
# also maybe call this function export instead
func serialize() -> Dictionary:
	return {
		"Name": get_name(),
		"Current Ammo": current_ammo,
#		"Reserve Ammo" <- maybe call this extra ammo
		"Cycled": cycled,
		"Loading": loading,
		"Shot Timer": get_current_shot_time(),
		"Draw Timer": get_current_draw_time(),
		"Reload Timer": get_current_reload_time(),
	}
#start_ammo := ammo, start_cycled := true, start_unloaded := false, start_extra_ammo := extra_amm
