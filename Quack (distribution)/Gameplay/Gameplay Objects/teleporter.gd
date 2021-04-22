extends Area

export var destination = Vector3()

func _ready():
	self.connect("body_entered", self, "collided")

func collided(body):
	if body is KinematicBody:
		body.set_translation(destination)
