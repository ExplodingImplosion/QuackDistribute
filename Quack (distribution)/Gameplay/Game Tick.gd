extends Object
class_name GameTick

var ticknum: int
var players: Dictionary
var events: Array
var is_snapshot_tick: bool

func _init(this_num: int, this_playerlist: Dictionary):
	ticknum = this_num
	players = this_playerlist

func add_event(which: TickEvent):
	events.append(which.export_event())

func export_tick() -> Dictionary:
	return {
		"ticknum": ticknum,
		"players": players,
		"events": events,
		# there was a point where the events bit was gonna use export_all_events(),
		# but frankly im moving away from objects and just using the static funcs
		# and turning things into arrays and dictionaries and stuff
		"is_snapshot_tick": is_snapshot_tick
	}

# for use if the events in the tick are actual TickEvent objects
func export_all_events() -> Array:
	var all_events: Array
	for each_event in events:
		all_events.append(each_event.export_event())
	return all_events

static func export_prebuilt(this_ticknum: int, these_players: Dictionary, these_events: Array, snapshot_tick: bool = false) -> Dictionary:
	return {
		"ticknum": this_ticknum,
		"players": these_players,
		"events": these_events,
		"is_snapshot_tick": snapshot_tick
	}

static func get_events(this_tick: Dictionary) -> Array:
	return this_tick["events"]
