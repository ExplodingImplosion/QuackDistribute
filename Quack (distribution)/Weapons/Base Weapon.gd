extends Spatial
class_name BaseWeapon

#modifiable variables that are meant to be acessed by children
export(float, 0, 10) var fire_rate = 0.0
export(int, 0, 500) var magsize = 0
export(float, 0, 10) var reload_speed = 0.0
export(int, 0, 500) var dmg = 0
export(int, 0, 100) var hs_mult = 2
export(int, "Automatic", "Single", "Pump/Bolt Action") var fire_type = 0
export(float, 0, 100) var vrecoil = 0.0
export(float, -100, 100) var hrecoil = 0.0
export(float, 0, 100) var aim_vrecoil = 0.0
export(float, -100, 100) var aim_hrecoil = 0.0
export(float, -100, 100) var hrecoil_freq = 5.0
export(float, -100, 100) var vrecoil_apex = 0
export(float, 0, 10) var max_vrecoil = 0.0
export(float, 0, 10) var curve_width = 0.0

#NOTE: Weapon stability is basically a rating of how much a gun sways during certain actions.
# when a weapon sways, the raycast that emits from the player is rotated on an axis, and requires the player
# to aim in an off-center fashion, similar to CS, in order to hit their target. Currently, weapon sway is
# NOT IMPLEMENTED, and these vars don't do anything

#determines the stability of the weapon when firing
export(float, 0, 1) var firing_stability = 1.0
#determines the stability of the weapon when moving
export(float, 0, 1) var movement_stability = 1.0
#determines the stability of the weapon when firing while aiming down sights
export(float, 0, 1) var aim_firing_stability = 1.0
#determines the stability of the weapon when moving while aiming down the sights
export(float, 0, 1) var aim_movement_stability = 1.0

#these are variables that are actually used. calculated when the gun is instanced
#shortens calculations, since they would otherwise be 1 - firing_stability
onready var fire_sway_factor = 1 - firing_stability
onready var move_sway_factor = 1 - movement_stability
onready var aim_fire_factor = 1 - aim_firing_stability
onready var aim_move_factor = 1 - aim_movement_stability

export(Curve) var sway_curve
export(Curve) var recoil_curve
export(Curve) var shot_curve

enum {FIRE, THROWGRENADE, SPAWN, KILL, DAMAGE, MAKESOUND}

#determines the "weight" of the gun. scalar value from 0 to 1. the player script yoinks this variable,
# and subtracts it from 1 to determine how fast the player should move while holding the gun
export(float, 0, 1) var weight = 0.0
#replaces the weight value in the player script when the player is aiming down the sights
export(float, 0, 1) var aim_weight = 0.0

#decides which section of buy/selection menu to place it in idk why i abbreviated lmg and dmr but not ar and
# smg. don't ask, lol
export(int, "Pistol", "Submachine Gun", "Shotgun", "Assault Rifle", "DMR", "Sniper Rifle", "LMG") var section
#decides how much (in dollars) the weapon should cost
export(int, 0, 10000) var price = 0

#modifiable cosmetic variables that don't impact gameplay
export(int, "9mm", "5.56", "7.62", ".300", ".45", ".50", "12 gauge", "4.6x30") var caliber

#defines the relevant nodes that the weapon will need to reference
onready var parent = $"../../"
onready var camera = $"../.."
onready var timer = $firetimer
onready var reloadtimer = $reloadtimer
export var sound = preload("res://Audio/SFX/Gunshots/test sound 2 16-bit.wav")
export(String, "Dropped Weapon", "Dropped M4", "Dropped AK", "Dropped 1911") var dropped_counterpart = "Dropped Weapon"

#references that scripts will access to change gun orientation/rotation
onready var tree = $tree
onready var state = tree.get("parameters/weapon state/playback")
onready var lean = "parameters/weapon state/aimdirs/blend_position"
onready var middleangles = "parameters/weapon state/aimdirs/0/blend_position"
onready var leftangles = "parameters/weapon state/aimdirs/1/blend_position"
onready var rightangles = "parameters/weapon state/aimdirs/2/blend_position"

#transient variables that are expected to be changed consistently throughout gameplay
var current_ammo: int
#might be worth changing canshoot to an int, so that different entities can tell the gun to not shoot by adding 1
# to the canshoot var. That way, if the gun is supposed to not be able to shoot, something like the firetimer
# doesn't override it with some kind of bit where it sets canshoot to true. in a way, an int version of canshoot
# would count how many events are preventing the gun from shooting, and puts them all in one var. actually,
# it might be worth it to split them into several different bools (but only while debugging), and then turn
# it into an increasing/decreasing int when the scripts are finished.
var canshoot := true
var shot := false
var loading := false
var current_recoil := 0.0
var recovering := false
var camreset: float
var recoverytime := 0
var zoomed := false
#transient variables that are the same as their counterparts without the "this_" prefix, when not zoomed in,
# and are updated to the ADS_ version when the player zooms in
onready var this_vrecoil = vrecoil
onready var this_hrecoil = hrecoil
onready var this_weight = weight
onready var this_move_factor = move_sway_factor
onready var this_fire_factor = fire_sway_factor

#single fire and pump/bolt action-exclusive variable that checks if the player has released the fire button
var releasedfire = true

#pump/bolt action-exclusive variable that checks if the bolt/pump has been cycled
#THIS VARIABLE HAS NOT BEEN IMPLEMENTED YET
var cycled = true

var sway = 0.0

var vertical = 0.0

#clamped delta var so that recoil never goes too crazy
var clelta = 0.01

#constant to quickly get 1/60 as a float with maximum floating point precision
const sixty = 0.016667

#transient variable used to determine how much the gun viewmodel is bouncing
# from recoil
var shotfactor = Vector2(0,0)

#transient variable. how much the gun should be swaying based on how fast its
# going relative to its max speed, then multiplied by its current movement
# swaying factor
var swayfactor = 0.0

var current_vrecoil = 0.0

var current_hrecoil = 0.0

func _ready():
	timer.set_wait_time(fire_rate)
	reloadtimer.set_wait_time(reload_speed)

func spawn(var ammo:= magsize):
	current_ammo = ammo

func _process(delta):
	# idk if we need to do get_parent() here
	if get_parent().is_network_master():
		if current_ammo < 1:
			canshoot = false
			if not loading:
				predict_reload()
		#maybe optimize w/ switch?
		if shot:
			clelta = clamp(delta, 0, sixty)
			#old formula: (max_vrecoil-(pow((magsize*vrecoil_apex)-current_recoil,2)/(magsize*vrecoil_apex/(max_vrecoil/magsize*vrecoil_apex))))
			#recoil bounce needs to be seriously worked on. the individual bounce of each shot shouldn't be tied to how much the muzzle climbs for an additional shot
			#old recoil bounce: pow(3, 1-((fire_rate - timer.time_left) * 30))
			#second recoil bounce (doesn't work properly): 42000 * pow(fire_rate/2 - (fire_rate - timer.time_left), 3)
			#add to the horizontal recoil calculation after the hrecoil * bit:
			# (sin(2 * (current_recoil/PI)))/abs(sin(current_recoil/PI)) * 
			# to get recoil that goes to both sides
			current_vrecoil = this_vrecoil * (max_vrecoil * exp( -0.1 * (pow(current_recoil - vrecoil_apex, 2)/curve_width))) * pow(3, 1-((fire_rate - timer.time_left) * 30)) * clelta
			current_hrecoil = this_hrecoil * sin((PI * current_recoil) / (2 * hrecoil_freq)) * pow(3, 1-((fire_rate - timer.time_left) * 30)) * clelta
			parent._aim(current_vrecoil , current_hrecoil, false)
			#this is a hack! don't use this (lmao)
			#////////
	#		parent._aim(420000 * pow(fire_rate/2 - (fire_rate - timer.time_left), 3) * delta, 0, false)
			#///////
	#		print(vrecoil * pow(3, 1-((fire_rate - timer.time_left) * 30)) * clelta)
			var shotx = clamp((current_hrecoil/this_hrecoil) * (this_fire_factor + swayfactor), -1, 1)
			var shoty = clamp((current_vrecoil/(this_vrecoil*max_vrecoil)) * (this_fire_factor + swayfactor), -1, 1)
			#this is dumb and there had better be a, well, better way of doing this
			# there should realistically be no extra if statement, and shotfactor
			# should just be changing based on a Vector2 of shotx and shoty without
			# another variable being declared. maybe a += isnt the way to do it, but
			# right now I cant think of another way to have it recreating the
			# recoil without taking the antiderivative of the recoil functions.
			# frankly, even in the current state of things, making a vector2 var
			# might actually take longer than turning shotx and shoty into a vector2
			# type twice. also, if this gets solved, make sure to check out the
			# shotfactor_recover func to see if its redundant/depreciated
			var shotxy = Vector2(shotx,shoty)
			if shotxy == Vector2(0,0):
				_shotfactor_recover(delta)
			else:
				shotfactor += shotxy
		else:
			if current_recoil != 0:
				current_recoil = clamp(current_recoil - delta/fire_rate, 0, 30)
				#being lazy in the player function means we don't need to update the viewmodel here anymore
				#parent.viewmodelcam.global_transform = parent.cam.global_transform
			if shotfactor != Vector2(0,0):
				_shotfactor_recover(delta)
		if recovering:
			if camera.get_rotation_degrees().x > camreset:
				#this needs some work lmaoooooooooooo
				parent._aim(-1 * vrecoil * delta, 0, false)
				#this is for debugging
				#print(camera.get_rotation_degrees().x - camreset)
			else:
				recoverytime = 0
			recoverytime = clamp(recoverytime - delta, 0, 20)
			if recoverytime <= 0:
				recovering = false
	#	parent.myHUD._update_var_1("sway:", sway)
	#	parent.`_3("velocity:", Vector2(direction.x, direction.z))
	#	parent.myHUD._update_var_3("shotfactor: ", parent.weapons[parent.current_weapon].shotfactor)
	#	parent.myHUD._update_var_2("vrec: ", parent.weapons[parent.current_weapon].current_vrecoil/clelta)
	#	parent.myHUD._update_var_1("hrec: ", parent.weapons[parent.current_weapon].current_hrecoil/clelta)
	#	parent.myHUD._update_var_2("anim position:", skrr)

#more or less just a macro for recovering since its called twice under certain
# conditions being met
func _shotfactor_recover(delta: float):
	shotfactor = Vector2(move_toward(shotfactor.x, 0, 1.5*delta),move_toward(shotfactor.y, 0, 1.5*delta))

func _shoot():
	#to be clear, i REALLY don't like the idea of adding ANY additional delays (if checks, stuff like that)
	# to any part of the script that shoots the gun. So hopefully I can figure out a way to axe this
	#fire type if check
	if fire_type == 0 || releasedfire == true:
		if canshoot:
			#reduces the gun's ammo
			current_ammo -= 1
			#makes sure that the gun doesn't shoot when it's not supposed to
			canshoot = false
			#force a raycast update. THIS IS NOT REDUNDANT. normally raycasts apparently only update in the 
			# _physics_process function
			#commented out code testing 0-frame recoil, currently breaks recoil recovery
			#parent._aim(vrecoil/10.0, hrecoil/10.0)
			
			#should probably rework how this is coded to not use multiple if statements, since there is probs
			# away more efficient way of doing this, with like, only 1 if check
			if fire_type != 0:
				releasedfire = false
			
			#ups the variable governing how much recoil to increase by 1
			current_recoil += 1
			#registers that the gun just fired. different from canshoot, which can be changed by external
			# entities. shot is intended for only the player to modify thru the gun.
			shot = true
			# suspends weapon recovery while the recoil is increasing
			recovering = false
			#if the gun isn't recovering, set the gun's resting point to it's current location, before any recoil
			# takes place ... THIS MAY BE REDUNDANT, if the camreset keeps being set in the _aim function
			if recoverytime == 0:
				camreset = camera.get_rotation_degrees().x
			#adds recovery time by however long it takes to shoot the gun. might be worth changing for single fire
			# and bolt/pump action guns
			recoverytime+=fire_rate
			#mmm, i think we're going to actually axe this, since hit detection is supposed to be done
			# server-side. At the same time, we might want to keep this collision detection around, so that we can
			# do checks for hit vfx predictions, etc
			#runs graphical stuff, plays the sound, animation, etc
			if tree["parameters/shoot gun/active"] == true:
				tree["parameters/shoot gun 2/active"] = true
			else:
				tree["parameters/shoot gun/active"] = true
#			if zoomed == true:
#				state.travel("ADS fire")
#			else:
#				state.travel("fire")
			Audio_Manager.play(self, sound, 80, 6,1 + 0.01 * current_vrecoil + 0.01 * current_hrecoil)
			#starts the firing timer
			timer.start()
			timer.connect("timeout", self, "_cycled", [], CONNECT_ONESHOT)

func _cycled():
	shot = false
	#now that the gun is done shooting upward, the camera recoil can start recovering. we tell the
	# _process function that this is ok by setting recovering to true
	recovering = true
	#makes sure that other circumstances aren't taking priority over this, and that is's cool to
	# let the gun shoot again. See the original declaration of canshoot as to why we might want
	# to change this if then statement simply into a canshoot -= 1
	if not loading and current_ammo > 0:
		canshoot = true

func _reload():
	if current_ammo < magsize and not loading:
		if zoomed == true:
			_unzoom()
		canshoot = false
		loading = true
		reloadtimer.start()
		if current_ammo > 0:
			state.travel("tacreload")
		else:
			state.travel("reload")


func _on_reloadtimer_timeout():
	current_ammo = magsize
	loading = false
	canshoot = true

func _cancel_reload():
	loading = false
	reloadtimer.stop()
	if current_ammo > 0:
		canshoot = true

func _ADS():
	if not zoomed and loading == false:
		zoomed = true
		parent.myHUD.crosshair.hide()
		this_vrecoil = aim_vrecoil
		this_hrecoil = aim_hrecoil
		this_weight = aim_weight
		this_fire_factor = aim_fire_factor
		this_move_factor = aim_move_factor
		state.travel("goto ADS")

func _unzoom():
	zoomed = false
	parent.myHUD.crosshair.show()
	this_vrecoil = vrecoil
	this_hrecoil = hrecoil
	this_weight = weight
	this_fire_factor = fire_sway_factor
	this_move_factor = move_sway_factor
	state.travel("leave ADS")

func _sway(delta, velocity, direction):
	var totalvel = abs(velocity.x)+abs(velocity.z)
	#depreciated code that doesn't do what it's supposed to do
	# it's supposed to find the 
#	var speed: float
#	if totalvel != 0:
#		speed = abs((velocity.x/totalvel) + (velocity.z/totalvel))
	#this might just be something to rework with a tween, either within this scene
	# or in the player's scene
	var totaldirection = abs(direction.x) + abs(direction.z)
	#maybe just do if direction != Vector3(0, direction.y, 0)
	if totaldirection > 0:
		if sway == 2.0:
			sway = 0.0
		else:
			sway = move_toward(sway, 2.0, delta)
		
	else:
		sway = move_toward(sway, round(sway), delta)
#	var skrr = Vector2(totalvel / ((weight - 1) * parent.maxwsp) * move_sway_factor * sin(2*PI*sway), 0)
#	other option:
	swayfactor = totalvel / ((1 - this_weight) * parent.maxwsp) * this_move_factor
	var skrr2 = swayfactor * -sin(2*PI*sway)
	vertical = move_toward(vertical, clamp(velocity.y, -1, 1), 2 * delta)
#	print(clamp(velocity.y, -1, 1))
	var skrr = Vector2(skrr2 + shotfactor.x, pow(skrr2,2)/5 - vertical + shotfactor.y)
#	tree[lean] = skrr.x/abs(skrr.x) * skrr.x
#	print("at sway value " + str(sway) + "and a speed of " + str(speed) + ", the weapon sways to value " + str(skrr) )
	tree[middleangles] = skrr
	tree[leftangles] = skrr
	tree[rightangles] = skrr
	tree[lean] += skrr.x


func drop():
#	print(preloader.get_resource(dropped_counterpart))
	var dropped = preloader.get_resource(dropped_counterpart).instance()
	dropped.spawn(current_ammo)
	parent.get_parent().add_child(dropped)
	dropped.global_transform.origin = parent.global_transform.origin + Vector3(0,2,0)
	dropped.set_rotation_degrees(parent.get_rotation_degrees())
	dropped.apply_central_impulse(Vector3(1,5,0))
#	parent.velocity.x + parent.cam.get_rotation_degrees
	queue_free()


# lmao
func predict_shot():
	_shoot()


# if we change how shooting works on the server from an input detection to an
# event that the server recieves from each client, then we don't have to do
# some of the advanced input logic that comes from the _shoot() script
# into this script, and potentially remove some overhead. in reality it's
# probably not a big deal, but it's good to have this here as a thought.
func calculate_shot():
#	print("shot is being calculated")
#	print(Engine.get_physics_interpolation_fraction())
	if fire_type == 0 || releasedfire == true:
		if canshoot:
			#reduces the gun's ammo
			current_ammo -= 1
			print(current_ammo)
			#makes sure that the gun doesn't shoot when it's not supposed to
			canshoot = false
			
			#should probably rework how this is coded to not use multiple if statements, since there is probs
			# away more efficient way of doing this, with like, only 1 if check
			if fire_type != 0:
				releasedfire = false
			
			#ups the variable governing how much recoil to increase by 1
			current_recoil += 1
			#registers that the gun just fired. different from canshoot, which can be changed by external
			# entities. shot is intended for only the player to modify thru the gun.
			shot = true
			
			# suspends weapon recovery while the recoil is increasing, commented
			# out since this might only need to be performed on the client
#			recovering = false
#			recoverytime+=fire_rate
#			if tree["parameters/shoot gun/active"] == true:
#				tree["parameters/shoot gun 2/active"] = true
#			else:
#				tree["parameters/shoot gun/active"] = true
			var testgd = get_parent().get_parent().get_parent().get_parent()
			testgd.node_events.append(testgd.tick_event.new(0, int(get_parent().name), FIRE))
#			Audio_Manager.play(self, sound, 80, 6,1 + 0.01 * current_vrecoil + 0.01 * current_hrecoil)
			
			# starts the firing timer
			timer.start()
			timer.connect("timeout", self, "_cycled", [], CONNECT_ONESHOT)

func display_shot():
	pass

func display_reload():
	pass

# this is here so that things that need to be set up properly when the gun is equipped
# actually happen
func equip():
	pass

# same thing but with putting the gun away
func put_away():
	pass

func predict_leave_ADS():
	pass

func predict_ADS():
	pass

func predict_reload():
	pass
