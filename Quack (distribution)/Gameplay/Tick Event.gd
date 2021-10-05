extends Object
class_name TickEvent

enum {FIRE, THROWGRENADE, SPAWN, KILL, DAMAGE, MAKESOUND, TRYPLANT, PLANT,
		TRYDEFUSE, DEFUSE, RELOAD, TEAMCHANGED, PLAYERREMOVED}
enum {TO, FROM, ADVANCED}

enum spawn{WHO, TRANSFORM, GUN1, GUN2, TEAM}
enum teamchanged{PLAYER, TEAM}

enum {TYPE, PARAMS}

#what object is calling the event (unique ID's for individual players, 0 for
# all players, and 1 for the server). should probably rework this so that all
# machines have an array of associations that can be called, such that these
# vars dont need to be excessively long for players and reduce badnwidth
# footprint. but to be entirely honest, since this is all testing, and a better
# system may be implemented, I won't even take the time to add that kind
# of functionality for all machines
var type: int
var params: Array
var extra_info: Array

func _init(event_type: int, event_params: Array = []):
	type = event_type
	params = event_params

static func get_event_params(this_event: Array) -> Array:
	return this_event[PARAMS]

static func spawn_player_weapon(this_playercontroller: PlayerController, this_weapon: BaseWeapon, this_gun: Dictionary) -> void:
	this_weapon.spawn(this_playercontroller,
			this_gun["Current Ammo"],
			this_gun.Cycled,
			this_gun.Loading,
			this_gun["Shot Timer"],
			this_gun["Draw Timer"],
			this_gun["Reload Timer"])

static func parse_event(this_event: Array) -> void:
#	print(this_event)
	match this_event[TYPE]:
		FIRE:
			pass
		THROWGRENADE:
			pass
		SPAWN:
			Lobby.my_client.emit_signal("player_spawned",
										this_event[PARAMS][spawn.WHO],
										this_event[PARAMS][spawn.TRANSFORM],
										Lobby.my_client.spawn_gamemode_primary(),
										Lobby.my_client.spawn_gamemode_secondary(),
#										this_event[PARAMS][spawn.GUN1],
#										this_event[PARAMS][spawn.GUN2],
										this_event[PARAMS][spawn.TEAM])
			
			
#			# LMFAOOOOOOOOOOOOOOOOOOOOO you know its bad when we be making vars
#			# this is just a semantics thing to make this atrocious code read slightly better
#			var event_params: Array = this_event[PARAMS]
##			var gun1: Dictionary = event_params[spawn.GUN1]
##			var gun2: Dictionary = event_params[spawn.GUN2]
#			Lobby.my_client.spawn_player(event_params[spawn.WHO],
#			event_params[spawn.TRANSFORM],
#			Lobby.my_client.spawn_gamemode_primary(),
#			Lobby.my_client.spawn_gamemode_secondary(),
#			event_params[spawn.TEAM])
#
##			var this_player: PlayerController = Lobby.my_client.get_player(event_params[spawn.WHO]).my_playercontroller
##			spawn_player_weapon(this_player, this_player.weapons[0], gun1)
##			spawn_player_weapon(this_player, this_player.weapons[1], gun1)
		KILL:
			pass
		DAMAGE:
			pass
		MAKESOUND:
			pass
		TRYPLANT:
			pass
		PLANT:
			pass
		TRYDEFUSE:
			pass
		DEFUSE:
			pass
		RELOAD:
			pass
		TEAMCHANGED:
			Lobby.my_client.emit_signal("player_joined_team", this_event[PARAMS][teamchanged.PLAYER],
																this_event[PARAMS][teamchanged.TEAM])
		PLAYERREMOVED:
			Lobby.playerlist[this_event[PARAMS][0]].delete_playercontroller()

static func make_event(event_type: int, event_params: Array) -> Array:
	return [event_type, event_params]

func export_event() -> Array:
	return [type, params]
