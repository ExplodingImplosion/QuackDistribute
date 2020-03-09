extends Node

export var fire_rate = 0.75
export var magsize = 4
export var reload_speed = 1

#onready var raycast = $"../Head/Camera/aim"
#onready var camra = $"../Head/Camera"
var current_ammo = magsize
var canshoot = true

var rocket = preload("rocket.tscn")
var loading = false

onready var player = self.get_parent().get_parent().get_parent()

func _ready():
	pass

func reload():
	while current_ammo < 4:
		print("reloading... ")
		player.myHUD.viewmodel.set_flip_v(true)
		yield(get_tree().create_timer(reload_speed), "timeout")
		print("loaded " + str(current_ammo))
		current_ammo += 1
		canshoot = true
	if current_ammo > 3:
		loading = false
		player.myHUD.viewmodel.set_flip_v(false)

func _process(delta):
	if is_network_master() and player.tabbedin == true:
		if current_ammo < 1:
			if not loading:
				canshoot = false
				reload()
				loading = true
		elif Input.is_action_just_pressed("shoot") and canshoot:
			rpc('_shoot')
		elif Input.is_action_just_pressed("reload"):
			if not loading:
				reload()
				loading = true

remotesync func _shoot():
	var rocketinst = rocket.instance()
	get_tree().get_root().add_child(rocketinst)
	rocketinst.parent = player
	rocketinst.global_transform = self.global_transform
	rocketinst.scale = Vector3(1, 1, 1)
	print("bang!")
	canshoot = false
	current_ammo -=1
	if is_network_master():
		player.myHUD.viewmodel.set_flip_h(true)
	yield(get_tree().create_timer(fire_rate), "timeout")
	canshoot = true
	if is_network_master():
		player.myHUD.viewmodel.set_flip_h(false)
#func damage():
#	if raycast.is_colliding():
#		var collider = raycast.get_collider()
#		if collider.is_in_group("enemies"):
#			collider.queue_free()
#			print("u shot " + collider.name)
