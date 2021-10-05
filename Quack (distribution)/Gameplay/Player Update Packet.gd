extends Object
class_name PlayerUpdatePacket

var updates: Array

func _init() -> void:
	pass

#func export_packet() -> Dictionary:
#	return {
#		"packets_recieved": PoolByteArray([]),
#		"updates": []
#	}

# enum'd array version of the above
enum {PACKETS_RECIEVED, UPDATES}
enum {INPUTS, INFO}
func export_packet() -> Array:
	return [updates, []]

static func make_packet(these_ticks: Array, these_updates: Array) -> Array:
	return [these_ticks, these_updates]
