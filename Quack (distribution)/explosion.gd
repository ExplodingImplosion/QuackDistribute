extends Spatial

var dmg = 25

var dist = Vector3()

var newdmg = dmg

var force = 30

var launchdir = Vector3()

func _ready():
	$Area.connect("body_entered", self, "boom")
	yield(get_tree().create_timer(0.5), "timeout")
	self.queue_free()

func boom(body):
	dist = body.get_translation().distance_to(self.get_translation())
	if body is KinematicBody:
		print("boop!")
		self.look_at(body.get_transform().origin, Vector3(0, 0, 0))
		var dir = self.get_global_transform().basis
		print("direction: " + str(dir))
		force = force * (100/11.201513 * (11.201513 - dist)) / 100
		body.booped(force, dir)
		newdmg = int(dmg * (100/4 * (4 - dist)) / 100)
		body.takedamage(newdmg)
	if body.is_in_group("enemies"):
		newdmg = 25 * (100/11.201513 * (11.201513 - dist)) / 100
		print("yeet " + str(newdmg))
		#damage them for dmg
	elif body.is_in_group("team1"):
		newdmg = (25 * (100/11.201513 * dist) / 100) * 2 / 5
		#damage them for 40% damage
