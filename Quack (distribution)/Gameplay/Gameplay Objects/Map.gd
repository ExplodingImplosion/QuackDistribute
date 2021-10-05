extends Spatial
class_name Map

export var icon: Texture
export var max_players: int
export var default_gamemode: PackedScene = preload("res://Gamemodes/Default.tscn")
export var radar_image: Texture

export var map_environment: Environment = preloader.get_resource("Default 3D Environment")

export var preferred_spawns_1: PoolIntArray
export var preferred_spawns_2: PoolIntArray

export var radar_unit_ratio: float = 1.0

#onready var spawns: Array = find_all_spawns()

func find_all_spawns() -> Array:
	return find_spawns_in_group("Spawns")

func find_team_spawns(team_id: int) -> Array:
	return find_spawns_in_group(str("Team %s Spawns"%[team_id]))

func find_atk_spawns() -> Array:
	return find_spawns_in_group("ATK Spawns")

func find_def_spawns() -> Array:
	return find_spawns_in_group("DEF Spawns")

func find_spawns_in_group(group: String) -> Array:
	var spawnlist: Array
	for spawn in get_tree().get_nodes_in_group(group):
		spawnlist.append(spawn)
	return spawnlist

func parse_spawns_by_child_list() -> void:
	for spawn in get_children():
		if spawn is Position3D and "Spawn" in spawn.get_name():
			pass

#func get_spawn_position(id: int) -> Vector3:
#	return spawns[id].global_transform.origin
