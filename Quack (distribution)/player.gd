extends KinematicBody

var cam_angle = 0
var sens = 0.05

var velocity=Vector3()
var direction = Vector3()

const maxsp = 40
const accel = 4

const grav = 9.8 * 3
const maxwsp = 16
const waccel = 6
const wdeccel = 8
const aaccel = 0.5
const adeccel = 0.5

const jump_strength = 10

const maxhp = 100
var hp = maxhp

var tabbedin = true

puppet var puppetpos = Vector3()
puppet var puppetdir = Basis()
puppet var puppetvel = Vector3()

#team status checker. -1 = selecting team, 0 = spectator, 1 to infinity = an ingame team competing
#var team = -1

#true/false ticker of if the player is dead or alive.
#var live = false

onready var HUD = preload("HUD.tscn")
onready var cam = $Head/Camera
onready var aimer = $Head/Camera/rlaunch
onready var aimpoint = $Head/Camera/projaimer.get_transform().origin
onready var spatial = get_node("/root/Spatial")
onready var myHUD = HUD.instance()

#var playername = 

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	aimer.look_at(aimpoint, Vector3(0, 0, 0))
	aimer.rotate_object_local(Vector3(0, 1, 0), deg2rad(180))
	if is_network_master():
		$Head/Camera/realhead.hide()
		$Head/Camera/realhead/bill.hide()
		add_child(myHUD)
		
	_update_hp()

func _input(event):
	if is_network_master() and tabbedin:
		if event is InputEventMouseMotion:
			$Head.rotate_y(deg2rad(-event.relative.x * sens))
			var change = -event.relative.y * sens
			if change + cam_angle < 90 and change + cam_angle > -90:
				$Head/Camera.rotate_x(deg2rad(change))
				cam_angle += change
		#send the head rotation
		#rset_unreliable(str(change), self.global_transform.origin)

func _process(delta):
	if (Input.is_action_just_pressed("ui_cancel")):
		if tabbedin == true:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			tabbedin = false
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			tabbedin = true

func _physics_process(delta):
	walk(delta)
	if is_network_master():
		self.myHUD.ammocount.text = "Ammo: " + str(aimer.current_ammo)
	#_update_hp()
	var lookaim= $Head/Camera.get_global_transform().basis
	if is_network_master():
		rset_unreliable('puppetpos', self.global_transform.origin)
		rset('puppetvel', velocity)
		rset('puppetdir', lookaim)
		if Input.is_action_just_pressed("checkrot"):
			print(lookaim)
			print(puppetdir)
	else:
		self.global_transform.origin = puppetpos
		velocity = move_and_slide(puppetvel)
		cam.global_transform.basis = puppetdir
	if get_tree().is_network_server():
		Network.update_position(int(name), self.global_transform.origin, puppetdir, puppetvel)

func fly(delta):
	direction = Vector3()
	
	var aim=$Head/Camera.get_global_transform().basis
	if Input.is_action_pressed("forward"):
		direction -=aim.z
	if Input.is_action_pressed("back"):
		direction +=aim.z
	if Input.is_action_pressed("left"):
		direction -=aim.x
	if Input.is_action_pressed("right"):
		direction +=aim.x
	
	direction = direction.normalized()
	
	var target = direction * maxsp
	
	velocity = velocity.linear_interpolate(target, accel * delta)
	
	move_and_slide(velocity)

remotesync func booped(force, dir):
	direction = Vector3()
	var boopdir = dir
	direction -= boopdir.z
	direction = direction.normalized()
	var target = direction * maxsp
	velocity = velocity.linear_interpolate(target, force * 0.016667)
	move_and_slide(velocity)
	
remotesync func selfboop(force):
	direction = Vector3()
	var boopdir = $Head/Camera.get_global_transform().basis
	direction += boopdir.z
	direction = direction.normalized()
	var target = direction * maxsp
	velocity = velocity.linear_interpolate(target, force * 0.016667)
	move_and_slide(velocity)

func walk(delta):
	direction = Vector3()
	var aim=$Head/Camera.get_global_transform().basis
	if is_network_master() and tabbedin:
		if Input.is_action_pressed("forward"):
			direction -=aim.z * Vector3(1, 0, 1)
		if Input.is_action_pressed("back"):
			direction +=aim.z * Vector3(1, 0, 1)
		if Input.is_action_pressed("left"):
			direction -=aim.x
		if Input.is_action_pressed("right"):
			direction +=aim.x
		if Input.is_action_just_pressed("booptest"):
			rpc_unreliable('selfboop', 20)
		if Input.is_action_just_pressed("turntest"):
			print("z coords: " + str(aim.z))
			print("x coords:" + str(aim.x))
		if is_on_floor() and Input.is_action_just_pressed("jump"):
			velocity.y += jump_strength
	direction = direction.normalized()
	velocity.y -= grav * delta
	
	var temp_velocity = velocity
	temp_velocity.y = 0
	
	var speed
	speed = maxwsp
	
	var target = direction * speed
	
	var acceleration
	if is_on_floor():
		if direction.dot(temp_velocity) > 0:
			acceleration = waccel
		else:
			acceleration = wdeccel
	else:
		if direction.dot(temp_velocity) > 0:
			acceleration = accel
		else:
			acceleration = adeccel
	
	temp_velocity = temp_velocity.linear_interpolate(target, acceleration * delta)
	
	velocity.x = temp_velocity.x
	velocity.z = temp_velocity.z
	
	velocity = move_and_slide(velocity, Vector3(0, 1, 0))

func takedamage(dmg):
	hp -= dmg
	if hp <= 0:
		hp = 0
		rpc('_die')
	_update_hp()

func _update_hp():
	if is_network_master():
		myHUD.health.text = "Health: " + str(hp)

remotesync func _die():
	$respawner.start()
	set_physics_process(false)
	for child in get_children():
		if child.has_method('hide'):
			child.hide()
	$bodyshape.disabled = true
	if is_network_master():
		myHUD.ammocount.hide()
		myHUD.health.hide()
		myHUD.viewmodel.hide()
		myHUD.spawntimer.show()
		$HUD/Viewport/TextureRect.hide()
	aimer.set_process(false)
	var timeleft = int($respawner.get_time_left())
	if is_network_master():
		myHUD.spawntimer.text = "Spawn in: " + str(timeleft)
	yield(get_tree().create_timer(1), "timeout")
	while timeleft > 0:
		if is_network_master():
			timeleft = int($respawner.get_time_left())
			myHUD.spawntimer.text = "Spawn in: " + str(timeleft + 1)
		yield(get_tree().create_timer(1), "timeout")
	rpc('_on_respawner_timeout')

remotesync func _on_respawner_timeout():
	set_physics_process(true)
	for child in get_children():
		if child.has_method('show'):
			child.show()
	$bodyshape.disabled = false
	hp = maxhp
	_update_hp()
	if is_network_master():
		myHUD.ammocount.show()
		myHUD.health.show()
		myHUD.viewmodel.show()
		myHUD.spawntimer.hide()
		$HUD/Viewport/TextureRect.show()
	global_transform.origin = spatial.get_respawn_position()
	aimer.set_process(true)
	aimer.current_ammo = aimer.magsize
	self.velocity = Vector3(0,0,0)
	self.direction = Vector3(0,0,0)

func init(playername, startPos, isPuppet):
	self.global_transform.origin = startPos
	#if isPuppet:
		
