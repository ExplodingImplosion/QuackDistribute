extends PacketPeerUDP
class_name ServerBrowserDialogue

enum {TIME, ADDY, PORT}
enum data{ADDY,PORT,PACKET,TIME,BUTTON}
enum serverinfo{MAP,MODE,MAXPLAYERS,CURRENTPLAYERS}

const default_send_port:= 42069
const default_recieve_port:= 25566
const default_deletion_threshold := 3
const default_interval: float = 1.0
const miles_ip := '73.234.173.172'
const sheila_wpi := '130.215.228.252'
const laptop_wpi := '130.215.228.244'
const server_ips := PoolStringArray([miles_ip, sheila_wpi, laptop_wpi])
const local_broadcast_ip := "255.255.255.255"
var server_list: Dictionary

var timer = Timer.new()
var interval: float
var send_port: int
var recieve_port: int
var deletion_threshold: int
var destination_ips: PoolStringArray

signal server_updated
signal server_deleted

func _init(this_interval: float = default_interval,
			this_port: int = default_send_port,
			this_recieve_port: int = default_recieve_port,
			this_deletion_threshold: int = default_deletion_threshold,
			these_destination_ips := server_ips):
	
	interval = this_interval
	timer.set_wait_time(interval)
	send_port = this_port
	deletion_threshold = this_deletion_threshold
	destination_ips = subtract_local_addresses_from_these_destinations(these_destination_ips)
	recieve_port = this_recieve_port
	set_broadcast_enabled(false)

func subtract_local_addresses_from_these_destinations(these_destinations: PoolStringArray):
	var local_addresses: PoolStringArray = IP.get_local_addresses()
	var new_destinations: PoolStringArray = these_destinations
	for address in local_addresses.size():
		for destination in these_destinations.size():
			if local_addresses[address] == these_destinations[destination]:
				new_destinations.remove(destination)
	return new_destinations

func parse_packets(valid_addresses: PoolStringArray, current_time: int):
	# current_time is passed to this func so that it OS.get_time_unix() isn't called
	# more than once when it doesn't need to be, since the only time parse_packets
	# is used is in the listen_on_interval function
	for each_packet in get_available_packet_count():
		print("packet recieved!")
		var server_ip = get_packet_ip()
		# frankly this bit is fuckin stupid, the whole bit with server address validation
		# is fuckin stupid. because if the whole point of validating an address is
		# to make sure the program doesnt crash from an array getting sent incorrectly,
		# then the program should just check the array to see whether or not it got
		# sent some valid info! shit like if info[0] is String &&, etc stuff like
		# that!
		if is_valid_server_address(server_ip, valid_addresses):
			parse_online_packet(current_time)
		else:
			parse_local_packet(server_ip, current_time)

func parse_online_packet(current_time: int) -> void:
	var server_port = get_packet_port()
#	print("server IP pre-packet is: %s"%[get_packet_ip()])
	var packet = get_packet()
#	print("server IP post-packet is: %s"%[get_packet_ip()])
	var info = parse_json(packet.get_string_from_ascii())
	print(info)
	# this is... insanely stupid.
	if info[2] is Array:
		update_server_list(server_info.new(info[2], info[0], info[1], current_time))
	else:
		update_server_list(server_info.new(info, get_packet_ip(), server_port, current_time))

func parse_local_packet(server_ip: String, current_time: int) -> void:
	var server_port = get_packet_port()
	var packet = get_packet()
#	print("server IP is apparently: %s"%[server_ip])
#	print("server IP pre-packet is: %s"%[get_packet_ip()])
	var info = parse_json(packet.get_string_from_ascii())
#	print("server IP post-packet is: %s"%[get_packet_ip()])
	print(info)
	update_server_list(server_info.new(info, server_ip, server_port, current_time))

func is_valid_server_address(this_address: String, valid_addresses: PoolStringArray) -> bool:
	return true if Array(valid_addresses).find(this_address) != -1 else false

func update_server_list(this_info: server_info):
	# makes sure the server isn't just some weirdo packet, since godot sends it
	# the first time... also probably protects against some other weirdness that
	# might happen
	if this_info.ip != '' and this_info.port > 0:
		if server_list.has(this_info.ip) == false:
			add_server_to_list(this_info)
		else:
			update_server_in_list(this_info)
		emit_signal("server_updated", this_info)

func add_server_to_list(this_info: server_info):
	print("new server detected on IP %s with port %s" % [this_info.ip, this_info.port])
	server_list[this_info.ip] = this_info

func update_server_in_list(this_info: server_info):
	server_list[this_info.ip].update_time(this_info.time)
	server_list[this_info.ip].update_info(this_info.info)
# old code for this that isn't intended to be used. But instead, this should get
# changed to specifically only update variables that can change mid-game
#	for item in this_info.info.size():
#		server_list[this_info.ip][item] = this_info.info[item]

class server_info:
#	extends Array (I fucking wish lmao)
	var info: Array
	var ip: String
	var port: int
	var time: int
	
	func _init(this_info: Array, this_ip: String, this_port: int, this_time: int):
		info = this_info
		ip = this_ip
		port = this_port
		time = this_time
	
	func update_time(this_time: int) -> void:
		time = this_time
	
	func update_info(this_info: Array) -> void:
		info = this_info

func sweep_servers_for_deletion(current_time: int):
	for addy in server_list:
		if server_list[addy].time - current_time >= deletion_threshold:
			server_list.erase(addy)
			emit_signal("server_deleted", addy)

func _begin_pinging(on_port:= send_port, these_destinations:= destination_ips):
	ping_on_interval(these_destinations, on_port)
	timer.connect("timeout", self, "ping_on_interval", [these_destinations, on_port])
	start_timer_if_stopped()
	
func _begin_listening(on_port:= recieve_port, to_addresses:= PoolStringArray(['0.0.0.0'])):
	print("Listening to %s on port %s" % [to_addresses, on_port])
	listen(on_port, '0.0.0.0')
	listen_on_interval(to_addresses)
	timer.connect("timeout", self, "listen_on_interval", [to_addresses])
	start_timer_if_stopped()

func start_timer_if_stopped() -> void:
	if timer.is_stopped() == true:
		timer.start()

func reset_timer_if_running() -> void:
	if timer.is_stopped() == false:
		timer.stop()
		timer.set_wait_time(interval)

func ping_on_interval(these_destinations: PoolStringArray, on_port: int):
	print("pinging browser...")
	for server in these_destinations:
		set_dest_address(server, on_port)
		put_packet(os_id_to_packet())

func listen_on_interval(to_addresses: PoolStringArray):
	print("listening for packets...")
	var current_time = OS.get_unix_time()
	# parsing packets is what updates the dialogue's internal information. if
	# I feel like it, I can further overengineer this and decouple some of the states
	# and functionalities and put them all nice and organized, but I don't fucking
	# feel like it right now, and so long as no one fucks around on a lower level
	# than this, refactoring it won't be incomprehensible/"rebuild-from-the-ground
	#-up type bullshit"
	parse_packets(to_addresses, current_time)
	sweep_servers_for_deletion(current_time)
	
func _stop_listening():
	print("listening stopped")
	close()
	if timer.is_connected("timeout", self, "listen_on_interval"):
		timer.disconnect("timeout", self, "listen_on_interval")
	reset_timer_if_running()

func _stop_pinging():
	print("pinging stopped")
	if timer.is_connected("timeout", self, "ping_on_interval"):
		timer.disconnect("timeout", self, "ping_on_interval")
	reset_timer_if_running()
	

func _begin_advertising(is_local: bool, on_port:= default_send_port):
	if is_local:
		set_broadcast_enabled(true)
		connect_timer_to_local_advertisement(on_port)
		set_dest_address(local_broadcast_ip, on_port)
		advertise_locally_on_interval()
	else:
		connect_timer_to_advertisement(destination_ips, recieve_port)
		advertise_on_interval(destination_ips, recieve_port)
	start_timer_if_stopped()

func connect_timer_to_advertisement(these_destination_ips: PoolStringArray, on_port: int) -> void:
	timer.connect("timeout", self, "advertise_on_interval", [these_destination_ips, on_port])

func connect_timer_to_local_advertisement(on_port: int) -> void:
	timer.connect("timeout", self, "advertise_locally_on_interval")

func _stop_advertising():
	set_broadcast_enabled(false)
	# fuck you this is dumb but also go fuck yourself
	if timer.is_connected("timeout", self, "advertise_on_interval"):
		timer.disconnect("timeout", self, "advertise_on_interval")
	elif timer.is_connected("timeout", self, "advertise_locally_on_interval"):
		timer.disconnect("timeout", self, "advertise_locally_on_interval")
	reset_timer_if_running()

func advertise_on_interval(these_destination_ips: PoolStringArray, on_port: int):
	for server in these_destination_ips:
		print("advertising server to %s"%[server])
		print("-----------------------------------------")
		set_dest_address(server, on_port)
		put_packet(info_to_packet())

func advertise_locally_on_interval() -> void:
	print("advertising server locally...")
	print("-----------------------------------------")
	put_packet(info_to_packet())

func info_to_packet() -> PoolByteArray:
	return to_json(Lobby.get_server_info()).to_ascii()

func os_id_to_packet() -> PoolByteArray:
	return to_json(OS.get_unique_id()).to_ascii()
