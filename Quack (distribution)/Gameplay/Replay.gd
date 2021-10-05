extends Object
class_name Replay
var tick_history: Array
var tickrate: int
var snapshot_tickrate: int
var lifetime_dirtied_set
var current_dirtied_set
const save_path: String = "user://replays/"
const debug_save_path: String = "res://userdata/replays/"

func _init(this_history: Array, rate: int, snapshot_rate: int, this_dirtied_set: Array = []):
		tick_history = this_history
		tickrate = rate
		snapshot_tickrate = snapshot_rate
		lifetime_dirtied_set = this_dirtied_set

func add(this_tick: GameTick):
	tick_history.append(this_tick.export_tick())

func add_exported(this_exported_tick: Dictionary) -> void:
	tick_history.append(this_exported_tick)

func get_tick(tick: int) -> Dictionary:
	return tick_history[tick]

func save():
	var clientorserverbool: bool = Lobby.get_tree().is_network_server() 
	var clientorserver: String
	if clientorserverbool:
		clientorserver = "server replay "
	else:
		clientorserver = "client %s replay " % [Lobby.selfid]
	var this_datetime = OS.get_datetime()
	var datetime_string = str(str(this_datetime["month"]) + "-" + str(this_datetime["day"]) + "-" + str(this_datetime["year"]) + "; " + str(this_datetime["hour"]) + "-" + str(this_datetime["minute"]) + " (" + str(this_datetime["second"]) + ")")
	# if all unique ID's are enclosed in curly brackets, then we should just add a space to these strings. but if we
	# ever do wind up deploying to web, then keeping the normal brackets as an indication of if there is no hardware
	# ID might be useful... so they're staying in for now
	var os_id_string = str(" [" + OS.get_unique_id() + "]")
	if tick_history != []:
		var replay_file = File.new()
		print("opening...")
		var this_file_name: String = str(clientorserver + datetime_string + os_id_string + ".txt")
		if OS.is_debug_build():
			this_file_name = debug_save_path + this_file_name
		else:
			this_file_name = save_path + this_file_name
		replay_file.open(this_file_name, File.WRITE)
		print("storing...")
		# there was a point where this was nesseccary because it like crashed
		# if it was done a certain way for a random reason. but that doesnt seem
		# to be happening rn
#		if clientorserverbool:
#			replay_file.store_var(serialize())
#		else:
#			replay_file.store_string(store_as_string())
		replay_file.store_string(store_as_string())
		print("closing...")
		replay_file.close()
		print("saved " + clientorserver + datetime_string + " at " + save_path)
	else:
		print("failed to save " + clientorserver + datetime_string + " replay. history is empty.")

func store_as_string() -> String:
	return var2str(serialize())

func store_as_json() -> String:
	return to_json(serialize())

func size() -> int:
	return tick_history.size()

func serialize(start_at: int = 0, end_at: int = tick_history.size()) -> Dictionary:
	return {
		# might not need to be a deep copy... im not entirely sure
		"tick_history": tick_history.slice(start_at, end_at - 1, true),
		"tickrate": tickrate,
		"snapshot_tickrate": snapshot_tickrate,
		"lifetime_dirtied_set": lifetime_dirtied_set,
		"current_dirtied_set": current_dirtied_set
	}



func serialize_as_array(start_at: int = 0, end_at: int = tick_history.size()) -> Array:
	return [tick_history, tickrate, snapshot_tickrate, lifetime_dirtied_set]
