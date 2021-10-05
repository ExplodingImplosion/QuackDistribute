extends PlayerInterface
class_name RemotePlayer

var my_id: int
# might be depreciated
#var respawn_timer: Timer = Timer.new()
var ticks_not_recieved: Array
var updates_recieved: Array

var alleged_info: Dictionary

func _init(id: int) -> void:
	my_id = id
	connect("tree_entered", self, "on_tree_entered")

func _ready() -> void:
	if OS.is_debug_build():
		if get_tree().is_network_server():
			set_name("Remote player %s %s"%[Lobby.peer.get_peer_address(my_id), my_id])
#			set_process(false)
		else:
			set_name("Remote player %s"%[my_id])

func tick_authoritative(delta: float) -> void:
	pass

func get_lobby_history() -> Replay:
	return Lobby.my_client.history

func get_lobby_history_size() -> int:
	return get_lobby_history().size() - 1

func get_most_recent_tick() -> Dictionary:
	return get_lobby_history().get_tick(get_lobby_history_size())

func get_second_most_recent_tick() -> Dictionary:
	return get_lobby_history().get_tick(get_lobby_history_size() - 1)

func get_earlier_aim_angle() -> Vector2:
	if get_most_recent_tick().players.has(my_id):
		return get_most_recent_tick().players[my_id].aim_angle
	else:
		return Vector2(0,0)

# next and earlier are really poorly worded

func get_next_aim_angle() -> Vector2:
	return get_next_player_state().aim_angle

func get_earlier_player_state() -> Dictionary:
	return get_second_most_recent_tick().players[my_id]

func get_next_player_state() -> Dictionary:
	return get_most_recent_tick().players[my_id]

func get_earlier_player_position() -> Vector3:
	return get_earlier_player_state().position

func get_next_player_position() -> Vector3:
	return get_next_player_state().position

# this func and the variable below it might be depreciated
func calculate_aim_angle_difference() -> void:
	aim_angle_difference = get_next_aim_angle() - get_earlier_aim_angle()

var aim_angle_difference: Vector2

# maybe move these to the Quack singleton
static func interpolate_vector2(from: Vector2, to: Vector2, fraction: float) -> Vector2:
	return Vector2(move_toward(from.x, to.x, fraction), move_toward(from.y, to.y, fraction))

static func interpolate_vector3(from: Vector3, to: Vector3, fraction: float) -> Vector3:
	return Vector3(move_toward(from.x, to.x, fraction), move_toward(from.y, to.y, fraction), move_toward(from.z, to.z, fraction))

func interpolate_aim(fraction: float) -> void:
	my_playercontroller.set_aim(interpolate_vector2(get_earlier_aim_angle(), get_next_aim_angle(), fraction))

func interpolate_position(fraction: float) -> void:
	my_playercontroller.global_transform.origin = interpolate_vector3(get_earlier_player_position(), get_next_player_position(), fraction)

#get_earlier_aim_angle().move_toward(get_next_aim_angle(), aim_angle_difference * fraction)

func _physics_process(delta: float) -> void:
	# this might be the wrong way around. yeah tbh doing this in the server tick
	# would be theoretically faster since the server doesnt have to check if
	# it's the server
#	pass
	if get_tree().is_network_server():
		server_tick_player(delta)

func server_tick_player(delta: float) -> void:
	if my_playercontroller:
		tick_puppet_simulate(delta, aim_angle)
		check_against_player_inputs()

func _process(delta: float) -> void:
# if the game is running a server and not hosting the _process func should be turned
# off, but since we haven't figured out how hosting is gonna work on the backend, we're leaving
# the _process function running for now, which means this bool needs to be checked every
# _process step
	if !get_tree().is_network_server():
		if my_playercontroller != null:
			tick_puppet_interpolate(Engine.get_physics_interpolation_fraction())
#			if my_playercontroller.global_transform.origin != 

func tick_puppet_interpolate(fraction: float) -> void:
	if get_second_most_recent_tick().players.has(my_id):
		interpolate_aim(fraction)
		interpolate_position(fraction)
	else:
		my_playercontroller.set_aim(get_next_aim_angle())
		my_playercontroller.global_transform.origin = get_next_player_position()

func tick_puppet_simulate(delta: float, aim_dir: Vector2) -> void:
	my_playercontroller.set_aim(aim_dir)
	my_playercontroller.move(delta)

func check_against_player_inputs() -> void:
	if alleged_info.has("position") && alleged_info.has("velocity"):
		var position_difference_alleged: Vector3 = (my_playercontroller.global_transform.origin - alleged_info.position).abs()
		var position_difference_actual: Vector3 = (my_playercontroller.global_transform.origin - get_next_player_position()).abs()
		if all_v3_components_smaller(position_difference_alleged, position_difference_actual):
			my_playercontroller.global_transform.origin = alleged_info.position
			my_playercontroller.velocity = alleged_info.velocity

func all_v3_components_smaller(v31: Vector3, v32: Vector3) -> bool:
	if v31.x < v32.x && v31.y < v32.y && v31.z < v32.z:
		return true
	else:
		return false

func update_player(adv_inptlst: PoolByteArray, aim_dir: Vector2, player_info: Dictionary) -> void:
	update_advanced_inputs(adv_inptlst)
	if my_playercontroller != null:
		my_playercontroller.parse_advanced_inputlist(advanced_inputs)
	aim_angle = aim_dir
	alleged_info = player_info

func update_advanced_inputs(this_advanced_inputlist: PoolByteArray) -> void:
	advanced_inputs = this_advanced_inputlist

func on_tree_entered() -> void:
	pass
	# this might be depreciated
#	if !Lobby.my_client.gamemode.respawns:
#		respawn_timer.queue_free()
#	else:
#		add_child(respawn_timer)
#		respawn_timer.set_wait_time(Lobby.my_client.gamemode.respawn_time)

