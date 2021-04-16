extends Node
class_name input_list

# Why did I make this a dictionary? It looks nice in the editor and makes sense
# with assigning things, but enumerating an array makes way more sense in the
# grand scheme of things...
#var inputs = {
#	"forward": false,
#	"back": false,
#	"left": false,
#	"right": false,
#	"jump": false,
#	"shoot": false,
#	"reload": false,
#	"zoom": false,
#	"gun1": false,
#	"gun2": false,
#	"melee": false,
#	"cyclegrenades": false,
#	"meleeweapon": false,
#	"grenade": false,
#	"crouch": false,
#	"walk": false
#

var inputs = [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false]
var input_angle = Vector2(0,0)

enum {FORWARD, BACK, LEFT, RIGHT, JUMP, SHOOT, RELOAD, ZOOM, GUN1, GUN2, MELEE, CYCLEGRENADES, MELEEWEAPON, GRENADE, CROUCH, WALK, INTERACT}

func _ready():
	pass

func change(input: int, newvalue: bool) -> void:
	inputs[input] = newvalue

func get_input(input: int) -> bool:
	return inputs[input]

#now this looks like the dumbest thing in the world, but it simplifies writing
# shit because all someone needs to type is "hey i want the player to have this"
# input marked as true, and it does it, without passing true or false
func input(input: int):
	inputs[input] = true

func get_all() -> Array:
	return inputs

#same thing as the input function
func release(input: int):
	inputs[input] = false
