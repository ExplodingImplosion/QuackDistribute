extends RigidBody
class_name DroppedWeapon

export(int, 0, 200) var ammo
export(bool) var cycled
export(bool) var unloaded
export(int, 0, 1000) var extra_ammo
export(String, "Base Weapon", "M4", "1911", "AK") var held_counterpart = "Base Weapon"


func _ready():
	pass


func spawn(start_ammo := ammo, start_cycled := true, start_unloaded := false, start_extra_ammo := extra_ammo):
	#yes this is redundant, but it makes sure that we always get the values we
	# intend to
	ammo = start_ammo
	cycled = start_cycled
	unloaded = start_unloaded
	#same reasons for redundancy
	extra_ammo = start_extra_ammo

func interact(node: Node):
	# This might be hella redundant because im pretty sure only players are
	# gonna interact with this lmfao
	var held = preloader.get_resource(held_counterpart).instance()
	held.spawn(ammo)
	if node.is_in_group("players"):
		print("skrr")
		held.global_transform.origin = held.get_parent().global_transform.origin
		queue_free()
