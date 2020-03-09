extends Spatial

var speed = 70
var dmg = 25
var velocity = Vector3()

var hit = false

var explosion = preload("explosion.tscn")

var parent

func _ready():
	$Area.connect("body_entered", self, "collided")
	
func _physics_process(delta):
	var fwd = global_transform.basis.z.normalized()
	global_translate(fwd * speed * delta)

func collided(body):
	if not hit:
		if body != parent:
			hit = true
			self.queue_free()
			var boom = explosion.instance()
			var scroot = get_tree().root.get_children()[0]
			scroot.add_child(boom)
			boom.global_transform = self.global_transform
			boom.scale = Vector3(1, 1, 1)
			if body is KinematicBody:
				body.takedamage(dmg)
				print(str(body) + " took damage!")
			if body.is_in_group("enemies"):	
				print("u shot " + body.name)
				var newdmg = dmg + float(boom.newdmg)
				print("newdmg: " + str(newdmg))
				#damage the enemy player
	
#func damage(value):
#	health_points -= value
#	if hp <= 0:
#		hp = 0
#		rpc('_die')
#	_update_hp()
