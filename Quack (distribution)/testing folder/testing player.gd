extends KinematicBody

#camera vars
var cam_angle := 0.0
var sens: float = 0.01 * settings.get_setting("Mouse", "Sensitivity")

#these are changed throughout player movement. velocity is the xyz value of how the player is moving through
# space. Direction, is the xyz value in which the player is attempting to move in. inputdir is a Vector2 of
# horizontal direction the player is attempting to move in
var velocity := Vector3()
var direction := Vector3()
var _snap := Vector3()
const FLOOR_NORMAL := Vector3(0, 1, 0)
const FLOOR_MAX_ANGLE := deg2rad(46.0)
var aim_angle := Vector2()
#inputdir is a vector2 that is refreshed once every process. with a max/min value of 1 and -1, pressing inputting
# forward increases the x value, and vice versa with backwards. The same can be said about the y value with
#right and left. When the physics process runs, the walk function changes its direction based on the
#inputted direction values
var inputdir := Vector2()

var crouching := false
var jumped := false
var walking := false

#determine the maximum speed a player can move at (if in air)
const maxsp := 40

#constants that determine the speeds/accelerations of various facets of the player's movement
const grav := 9.8 * 3
const maxwsp := 10
const accel := 4
const deccel := 8
const aaccel := 0.25
const adeccel := 0.0125
const jump_strength := 10
const crouch_factor := 0.3
const walk_factor := 0.5

#determines a player's max hp, initializes the player's hp as 
const maxhp := 100
var hp : float = maxhp

var dead := false

#network vars
var inputs := input_list.new()
var inputinfo := []
var timestep := 0

#weapon vars
var weapons := [null, null, null]
var current_weapon := 0
var last_weapon := 1
var spawnweapon: Node = null
var zoomed := false

var grenades := []
var current_nade = null

#gamestate vars
var team := 0

var this_crouch_factor := 1.0
var this_walk_factor := 1.0

#onready vars used to simplify the references of various nodes
onready var cam := $"Head/World Camera"
onready var reference_model := $"reference (Delete later)"

#used for input parsing from an array
enum {FORWARD, BACK, LEFT, RIGHT, JUMP, SHOOT, RELOAD, ADS, GUN1, GUN2, MELEE, CYCLEGRENADES, MELEEWEAPON, GRENADE, CROUCH, WALK, DROP, INTERACT}

enum {FFA, TEAM1, TEAM2, TEAM3, TEAM4, TEAM5, TEAM6, TEAM7, TEAM8, TEAM9, TEAM10, TEAM11, TEAM12, TEAM13, TEAM14, TEAM15, TEAM16, TEAM17, TEAM18, TEAM19, TEAM20}

func _process(delta: float):
	if is_network_master():
		sim_with_inputs(delta)
	else:
		simulate(inputs.inputs, inputs.input_angle, delta)
	
# maybe this should go in the test.gd script so that on servers, players are
# 100% confirmed simulated BEFORE the tick gets processed
func _physics_process(delta: float):
	if get_tree().is_network_server():
		simulate(inputs.inputs, inputs.input_angle, delta)

func sim_with_inputs(delta: float):
	inputdir = Vector2(0,0)
	if Input.is_action_pressed("forward"):
		inputdir.x = clamp(inputdir.x + 1, 0, 1)
		inputs.input(FORWARD)
	else:
		inputs.release(FORWARD)
	if Input.is_action_pressed("back"):
		inputdir.x = clamp(inputdir.x-1, -1, 0)
		inputs.input(BACK)
	else:
		inputs.release(BACK)
	
	if Input.is_action_pressed("left"):
		inputdir.y = clamp(inputdir.y-1, -1, 0)
		inputs.input(LEFT)
	else:
		inputs.release(LEFT)
	
	if Input.is_action_pressed("right"):
		inputdir.y = clamp(inputdir.y+1, 0, 1)
		inputs.input(RIGHT)
	else:
		inputs.release(RIGHT)
	
	if Input.is_action_just_pressed("jump"):
		inputs.input(JUMP)
		# predict the jump
		_jump()
	else:
		inputs.release(JUMP)
	
	if Input.is_action_pressed("crouch"):
		inputs.input(CROUCH)
	else:
		inputs.release(CROUCH)
	
	if Input.is_action_pressed("shoot"):
		inputs.input(SHOOT)
		if weapons[current_weapon] != null:
			weapons[current_weapon].predict_shot()
	else:
		inputs.release(SHOOT)
	
	#if the weapon the player is holding isn't full-auto, tells the gun the
	# player stopped holding fire. This is advanced input logic, and shouldn't
	# be sent to the server/input list
	if Input.is_action_just_released("shoot"):
		pass
	
	if Input.is_action_pressed("reload"):
		inputs.input(RELOAD)
		if weapons[current_weapon] != null:
			weapons[current_weapon].predict_reload()
	else:
		inputs.release(RELOAD)
	
	if Input.is_action_pressed("zoom"):
		inputs.input(ADS)
		if weapons[current_weapon] != null:
			weapons[current_weapon].predict_ADS()
	else:
		inputs.release(ADS)
		if weapons[current_weapon] != null:
			weapons[current_weapon].predict_leave_ADS()
	
	#this is the bit where it gets a little more complicated, since "last gun"
	# and stuff like that is all gonna be done clientside.
	
	if Input.is_action_just_pressed("lastgun"):
		pass
	if Input.is_action_just_pressed("gun1"):
		inputs.input(GUN1)
	if Input.is_action_just_pressed("gun2"):
		inputs.input(GUN2)
	if Input.is_action_just_pressed("meleeweapon"):
		inputs.input(MELEEWEAPON)
	if Input.is_action_just_pressed("cyclegrenades"):
		inputs.input(CYCLEGRENADES)
	
	if Input.is_action_just_pressed("melee"):
		inputs.input(MELEE)
	
	if Input.is_action_just_pressed("grenade"):
		inputs.input(GRENADE)
	
	if Input.is_action_pressed("walk"):
		inputs.input(WALK)
	
	if Input.is_action_just_pressed("drop"):
		inputs.input(DROP)
	
	if Input.is_action_just_pressed("interact"):
		inputs.input(INTERACT)
	
	if Input.is_action_just_pressed("ui_cancel"):
		# this is hacky and dumb but fuck you
		var pause_menu = get_parent().get_parent().pause_menu
		# this is_proicessing_input shit is extra hacky and dumb, but fuck you
		# twice!
		if is_processing_input():
			if pause_menu.is_visible():
				pause_menu.hide()
			else:
				set_process_input(false)
				pause_menu._display()
	
	move(delta)

# I think this needs to get changed, since I'm pretty sure that currently this
# will cause the client to change LITERALLY EVERYONE's aim on their side
func _input(event):
	if is_network_master() and  event is InputEventMouseMotion:
		_aim(-event.relative.y  * sens, -event.relative.x * sens)

func _aim(amountx, amounty, player_influenced = true):
	aim_angle = Vector2(clamp(aim_angle.x + amountx, -90, 90), aim_angle.y + amounty)
	$Head.set_rotation_degrees(Vector3(aim_angle.x, aim_angle.y, 0))
	# could do set_rotation_degrees the way I did with _correct_aim, especially
	# considering that deg2rad probs takes more time
	reference_model.rotate_y(deg2rad(amounty + 180))

func simulate(these_inputs: Array, correction_angle: Vector2, delta: float):
	_apply_inputs(these_inputs)
	_correct_aim(correction_angle)
	move(delta)

func _change_health(modifier: int):
	hp += modifier

func _set_health(newhealth: int):
	hp = newhealth

func _respawn(location: Vector3):
	hp = maxhp
	global_transform.origin = location

func _correct_aim(angle: Vector2):
	aim_angle = Vector2(clamp(angle.x, -90, 90), angle.y)
	$Head.set_rotation_degrees(Vector3(aim_angle.x, aim_angle.y, 0))
	reference_model.set_rotation_degrees(Vector3(-90,aim_angle.y + 180,0))

func _correct_pos(position: Vector3):
	set_translation(position)

func _correct_direction(newdir: Vector3):
	direction = newdir

func _correct_velocity(newvel: Vector3):
	velocity = newvel

func _change_team(newteam: int):
	team = newteam

func _ready():
	if is_network_master():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		reference_model.set_visible(false)
		$Head/MeshInstance.set_visible(false)
		cam.set_current(true)
	elif get_tree().is_network_server():
		set_process(false)

func _apply_state(newstate):
	#checks the difference between the client's assumption of the player's position
	# and what the server said their position was
	var position_difference = abs(get_translation() - newstate.position)
	
	#if the position_difference is greater than 5 cm then it forces the client
	# to change their position to what the server said it was
	if position_difference.x >= 0.05 || position_difference.y >= 0.05 || position_difference.z >= 0.05:
		_correct_pos(newstate.position)
	
	#same thing but with their character's direction (used for momentum/movement calculations)
	var direction_difference := abs(direction - newstate.direction)
	
	#the player has a degree of control over their direction since they dictate their inputs
	# therefore there are additional checks done to ensure that we aren't forcing the player out
	# of taking certain actions
	
	
	#same thing as those above
	var velocity_difference := abs(velocity - newstate.velocity)
	
	#velocity is similar to the situation with direction, in that players change aspects of it
	
	
	#this is an easy thing to do, since HP should always be synchronized
	# and differences dont need to be taken into account. it's a binary of:
	# Is my HP correct, or is it not? Correct it if it isn't
	if hp != newstate.hp:
		_set_health(newstate.hp)
	
	#similar logic to a change in HP, but in the context of if the player is
	# making contact with a floor or not
	if is_on_floor() != newstate.onfloor:
		pass
	
	#same binary principal as earlier, but with player being dead or not
	if dead != newstate.dead:
		pass
	
	#inputs should always be updated, since they will always change
	if is_network_master() != true:
		inputs = newstate.inputs
	
	#this probably is not something to update every frame
	if team != newstate.team:
		_change_team(newstate.team)
	
	#this should probs be more complicated lmfao
	if weapons != newstate.weapons:
		weapons = newstate.weapons
	
	#same here
	if crouching != newstate.crouching:
		crouching = newstate.crouching
	
	#theres gonna need to be some more work going on
	if current_weapon != newstate.current_weapon:
		pass
		#_change_weapon(newstate.current_weapon)

#what with how the new simulate function works, passing the inputs array twice (from the test.gd script down)
# to the simulate function, and then down from simulate into this function, we might just want to change
# how it works, or maybe even just move _apply_inputs directly into simulate. dunno yet, though

#Another thing to note is that the _apply_inputs setup could be simplified by
# a couple bool checks if the player's sim_with_inputs function built the
# input direction vector2 and sent it to the input_list that the server accepted.
# the issue with this is everything else is a bool, and adding a vector2 might
# complicate things down the road if the inputlist winds up needing to only
# be bools (like 0's and 1's, or something)
func _apply_inputs(inputs: Array):
	inputdir = Vector2()
	if inputs[FORWARD] == true:
		inputdir.x += 1
	else:
		pass
	
	if inputs[BACK] == true:
		inputdir.x -= 1
	else:
		pass
	
	if inputs[LEFT] == true:
		inputdir.y -= 1
	else:
		pass
	
	if inputs[RIGHT] == true:
		inputdir.y += 1
	else:
		pass
	
	if inputs[JUMP] == true:
# and jumped == false <-- (maybe include this)
		_jump()
	else:
		pass
	
#	if inputs[CROUCH] == true:
#		crouching = true
#	else:
#		crouching = false
	
	if inputs[CROUCH] != crouching:
		crouching = inputs[CROUCH]
	
	if inputs[SHOOT] == true:
		if get_tree().is_network_server():
			weapons[current_weapon].calculate_shot()
#		else:
#			weapons[current_weapon].display_shot()
	else:
		pass
	
	if inputs[RELOAD] == true:
		if get_tree().is_network_server():
			weapons[current_weapon]._reload()
		else:
			weapons[current_weapon].display_reload()
	else:
		pass
	
	if inputs[ADS] == true:
		pass
	else:
		pass
	
	if inputs[GUN1] == true:
		pass
	else:
		pass
	
	if inputs[GUN2] == true:
		pass
	else:
		pass
	
	if inputs[MELEE] == true:
		pass
	else:
		pass
	
	if inputs[MELEEWEAPON] == true:
		pass
	else:
		pass
	
	if inputs[CYCLEGRENADES] == true:
		pass
	else:
		pass
	
	if inputs[GRENADE] == true:
		pass
	else:
		pass
	
	
	
#	for input in inputs.size():
#		match(input):
#			"forward":
#				pass
#			"back":
#				pass
#			"left":
#				pass
#			"right":
#				pass
#			"jump":
#				pass
#				if is_on_floor():
#					pass
#			#crouching might want to send an event to toggle the player crouching instead
#			"crouch":
#				pass
#			#"releasecrouch":
#				#pass
#			"shoot":
#				pass
#			"reload":
#				pass
#			"ADS":
#				pass
#			#"releaseADS":
#				#pass
#			#lastgun might not be worth it, and might be better to just have the "last gun" part of the game
#			#logic be client-exclusive, and just wind up sending the server whatever gun the client wound
#			#up switching to
#			"lastgun":
#				pass
#			"gun1":
#				pass
#			"gun2":
#				pass
#			"meleeweapon":
#				pass
#			#see the comment in regards to "lastgun". if we wind up changing how lastgun works on the server/
#			#other clients, then we should def change this, too.
#			"cyclegrenades":
#				pass
#			"melee":
#				pass
#			"grenade":
#				pass


func move(delta: float):
	direction = Vector3()
	var aim = $Head.get_global_transform().basis
	if inputdir.x > 0:
		direction -=aim.z * Vector3(1, 0, 1)
	elif inputdir.x < 0:
		direction +=aim.z * Vector3(1, 0, 1)
	if inputdir.y > 0:
		direction +=aim.x
	elif inputdir.y < 0:
		direction -=aim.x
	direction.y = 0
	direction = direction.normalized()
	
	var speed: int
	var acceleration
	var _snap: Vector3
	if is_on_floor():
		if jumped == true:
			jumped = false
		else:
			_snap = Vector3(0, -1, 0)
		
		#conditions that dictate player speed based on if they're going forward,
		# strafing or going backwards.
		if inputdir.x < 0:
			speed = maxwsp * 0.65
		elif inputdir.y != 0 and inputdir.x < 1:
			speed = maxwsp * 0.85
		else:
			speed = maxwsp
		speed *= this_crouch_factor * this_walk_factor
		# LMFAO dont forget to turn this shit back on
#		speed *= (1 - weapons[current_weapon].this_weight) * this_crouch_factor * this_walk_factor
	
	velocity.y -= grav * delta
	
	var temp_vel := velocity
	temp_vel.y = 0
	var target := direction * speed
	var temp_accel: float
	if direction.dot(temp_vel) > 0:
		temp_accel = accel
	else:
		temp_accel = deccel
	
	temp_vel = temp_vel.linear_interpolate(target, temp_accel * delta)
	velocity.x = temp_vel.x
	velocity.z = temp_vel.z
	
	if direction.dot(velocity) == 0:
		var vel_clamp := 0.25
		if velocity.x < vel_clamp and velocity.x > -vel_clamp:
			velocity.x = 0
		if velocity.z < vel_clamp and velocity.z > -vel_clamp:
			velocity.z = 0
	
	var moving = move_and_slide_with_snap(velocity, _snap, FLOOR_NORMAL, true, 4, FLOOR_MAX_ANGLE)
	if is_on_wall():
		velocity = moving
	else:
		velocity.y = moving.y

func get_inputs() -> Array:
	return inputs.get_all()

# I stg if these all go to waste im finna be pissed
# update: all to waste :D

func get_global_transform_origin() -> Vector3:
	return global_transform.origin

func get_direction() -> Vector3:
	return direction

func get_velocity() -> Vector3:
	return velocity

func get_aim_angle() -> Vector2:
	return aim_angle

func get_hp() -> float:
	return hp

func get_dead() -> bool:
	return dead

func get_weapons() -> Array:
	return weapons

func get_crouching() -> bool:
	return crouching

func get_current_weapon() -> int:
	return current_weapon

func switch_to():
	reference_model.hide()
	cam.set_current(true)
	cam.get_parent().get_node("MeshInstance").hide()
#	if weapons[0] != null:
#		weapons[0].hide()
#	if weapons[1] != null:
#		weapons[1].hide()

func switch_from():
	reference_model.show()
	cam.set_current(false)
	cam.get_parent().get_node("MeshInstance").show()

func give_item(item: Node):
	add_child(item)

func spawn(location: Vector3, gun1, gun2):
	global_transform.origin = location
	$Head.add_child(gun1)
	gun1.spawn()
	$Head.add_child(gun2)
	gun2.spawn()
	weapons[0] = gun1
	weapons[1] = gun2
	if is_network_master() == false:
		weapons[0].hide()
		weapons[1].hide()


func _jump():
	if is_on_floor():
		_snap = Vector3(0, 0, 0)
		jumped = true
		velocity.y += jump_strength
