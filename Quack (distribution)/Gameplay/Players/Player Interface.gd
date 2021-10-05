extends Node
class_name PlayerInterface

var my_playercontroller: PlayerController
var team: int = -1
# maybe this should be exclusive to local players
var tick_inputs: Array = InputList.get_default_inputs()
var advanced_inputs: PoolByteArray = PoolByteArray([1,0,0,0,0,0,0,0,0,0,0,0,0,0,
													0,0,0,0,0,0,0,0,0])
var aim_angle: Vector2 = Vector2(0,0)
# this enum should be same as the InputList.advancedenum
enum	{DELTAFRAMES, FORWARD, BACK, LEFT, RIGHT, JUMP, SHOOT, RELOAD, ADS, GUN1,
		GUN2, MELEE, CYCLEGRENADES, MELEEWEAPON, GRENADE, CROUCH, WALK, DROP,
		INTERACT, LASTGUN}

func _ready():
	pass

func assign_playercontroller(this_playercontroller: PlayerController):
	my_playercontroller = this_playercontroller
#	my_playercontroller.cam.set_current(true)
	# maybe just turn this whole func into a virtual func and make this go_first_person
	# thing a thingy for local players only
	print("%s playercontroller %s assigned!"%[get_name(), this_playercontroller])
	# this is insanely stupid that its done here with a check instead of a virtual
	# function, but this isnt unsafe to do since remote players will never be network
	# masters, and local players always will be
	if is_network_master():
		if !is_connected("mouse_moved", self, "aim_player"):
			connect("mouse_moved", self, "aim_player")
		my_playercontroller.go_first_person()

# if any changes are made here also check out the local player delete_playercontroller function
func delete_playercontroller() -> void:
	if my_playercontroller:
		Lobby.my_client.entities.players.erase(my_playercontroller.owner_id)
		my_playercontroller.queue_free()
		# this might be redundant but this wont really hurt that much
		my_playercontroller = null
		

func on_playercontroller_deleted() -> void:
	my_playercontroller = null

func set_team(this_team: int):
	team = this_team

static func clamp_vector2(this_vector: Vector2) -> Vector2:
	return Vector2(clamp_normalize(this_vector.x), clamp_normalize(this_vector.y))

static func clamp_normalize(this_value: float) -> float:
	return clamp(this_value, -1, 1)
