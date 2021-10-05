extends Object
class_name GameplayPacket

var ticks: Dictionary

func _init():
	pass

static func create_packet(these_ticks: Array) -> Dictionary:
	var this_packet: Dictionary
	for tick in these_ticks:
		this_packet[tick.ticknum] = tick
#	this_packet.updatesnotrecieved
	return this_packet
