extends Area

func _ready():
	self.connect("body_entered", self, "kill")

func kill(body):
	if body is KinematicBody:
		body.rpc('_die', body.myname)
