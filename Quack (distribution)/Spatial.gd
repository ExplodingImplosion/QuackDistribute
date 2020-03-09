extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var spawnpoint = $"Spawnpoint1-1"


# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().connect('network_peer_disconnected', self, '_on_player_disconnected')
	get_tree().connect('server_disconnected', self, '_on_server_disconnected')
	
	var new_player = preload('res://player.tscn').instance()
	new_player.name = str(get_tree().get_network_unique_id())
	new_player.set_network_master(get_tree().get_network_unique_id())
	add_child(new_player)
	var info = Network.self_data
	new_player.init(info.name, info.position, false)

func _process(delta):
	if (Input.is_action_just_pressed("restart")):
		get_tree().reload_current_scene()

func get_respawn_position():
		return spawnpoint.global_transform.origin

func _on_player_disconnected(id):
	get_node(str(id)).queue_free()

func _on_server_disconnected():
	get_tree().change_scene('res://interface/Menu.tscn')
