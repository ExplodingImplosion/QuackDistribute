class_name InputList

enum inputenum {MOVEMENT, JUMP, SHOOT, RELOAD, ADS, GUN1, GUN2, MELEE, CYCLEGRENADES,
				MELEEWEAPON, GRENADE, CROUCH, WALK, DROP, INTERACT, LASTGUN}
var inputs: Array = [Vector2(0,0), false, false, false, false, false, false, false, false, false, false, false, false, false, false, false]

static func get_default_inputs() -> Array:
	return [Vector2(0,0), false, false, false, false, false, false, false, false, false, false, false, false, false, false, false]

enum inputlistenum {FORWARD, BACK, LEFT, RIGHT, JUMP, SHOOT, RELOAD, ADS, GUN1,
					GUN2, MELEE, CYCLEGRENADES, MELEEWEAPON, GRENADE, CROUCH,
					WALK, DROP, INTERACT, LASTGUN}
var inputlist: PoolByteArray

var advanced_inputlist: PoolByteArray
enum advancedenum {DELTAFRAMES, FORWARD, BACK, LEFT, RIGHT, JUMP, SHOOT, RELOAD,
					ADS, GUN1, GUN2, MELEE, CYCLEGRENADES, MELEEWEAPON, GRENADE,
					CROUCH, WALK, DROP, INTERACT, LASTGUN}

static func get_keyboard_inputs() -> Array:
	var these_inputs: Array = get_default_inputs()
	if Input.is_action_pressed("forward"):
		these_inputs[inputenum.MOVEMENT].x += 1
	if Input.is_action_pressed("back"):
		these_inputs[inputenum.MOVEMENT].x -= 1
	if Input.is_action_pressed("left"):
		these_inputs[inputenum.MOVEMENT].y -= 1
	if Input.is_action_pressed("right"):
		these_inputs[inputenum.MOVEMENT].y += 1
	if Input.is_action_pressed("walk"):
		these_inputs[inputenum.WALK] == true
		these_inputs[inputenum.MOVEMENT] *= 0.5
	if Input.is_action_just_pressed("jump"):
		these_inputs[inputenum.jump] == true
	if Input.is_action_pressed("crouch"):
		these_inputs[inputenum.CROUCH] == true
	if Input.is_action_pressed("shoot"):
		these_inputs[inputenum.SHOOT] == true
	if Input.is_action_pressed("reload"):
		these_inputs[inputenum.RELOAD] == true
	if Input.is_action_pressed("zoom"):
		these_inputs[inputenum.ADS] == true
	if Input.is_action_just_pressed("lastgun"):
		these_inputs[inputenum.LASTGUN] == true
	if Input.is_action_just_pressed("gun1"):
		these_inputs[inputenum.GUN1] == true
	if Input.is_action_just_pressed("gun2"):
		these_inputs[inputenum.GUN2] == true
	if Input.is_action_just_pressed("meleeweapon"):
		these_inputs[inputenum.MELEEWEAPON] == true
	if Input.is_action_just_pressed("cyclegrenades"):
		these_inputs[inputenum.CYCLEGRENADES] == true
	if Input.is_action_just_pressed("melee"):
		these_inputs[inputenum.MELEE] == true
	if Input.is_action_just_pressed("grenade"):
		these_inputs[inputenum.GRENADE] == true
	if Input.is_action_just_pressed("drop"):
		these_inputs[inputenum.DROP] == true
	if Input.is_action_just_pressed("interact"):
		these_inputs[inputenum.INTERACT] == true
	return these_inputs

static func get_keyboard_inputlist() -> PoolByteArray:
	var this_inputlist: PoolByteArray
	if Input.is_action_pressed("forward"):
		this_inputlist.append(inputlistenum.FORWARD)
	if Input.is_action_pressed("back"):
		this_inputlist.append(inputlistenum.BACK)
	if Input.is_action_pressed("left"):
		this_inputlist.append(inputlistenum.LEFT)
	if Input.is_action_pressed("right"):
		this_inputlist.append(inputlistenum.RIGHT)
	if Input.is_action_pressed("walk"):
		this_inputlist.append(inputlistenum.WALK)
	if Input.is_action_just_pressed("jump"):
		this_inputlist.append(inputlistenum.JUMP)
	if Input.is_action_pressed("crouch"):
		this_inputlist.append(inputlistenum.CROUCH)
	if Input.is_action_pressed("shoot"):
		this_inputlist.append(inputlistenum.SHOOT)
	if Input.is_action_pressed("reload"):
		this_inputlist.append(inputlistenum.RELOAD)
	if Input.is_action_pressed("zoom"):
		this_inputlist.append(inputlistenum.ADS)
	if Input.is_action_just_pressed("lastgun"):
		this_inputlist.append(inputlistenum.LASTGUN)
	if Input.is_action_just_pressed("gun1"):
		this_inputlist.append(inputlistenum.GUN1)
	if Input.is_action_just_pressed("gun2"):
		this_inputlist.append(inputlistenum.GUN2)
	if Input.is_action_just_pressed("meleeweapon"):
		this_inputlist.append(inputlistenum.MELEEWEAPON)
	if Input.is_action_just_pressed("cyclegrenades"):
		this_inputlist.append(inputlistenum.CYCLEGRENADES)
	if Input.is_action_just_pressed("melee"):
		this_inputlist.append(inputlistenum.MELEE)
	if Input.is_action_just_pressed("grenade"):
		this_inputlist.append(inputlistenum.GRENADE)
	if Input.is_action_just_pressed("drop"):
		this_inputlist.append(inputlistenum.DROP)
	if Input.is_action_just_pressed("interact"):
		this_inputlist.append(inputlistenum.INTERACT)
	return this_inputlist

# this is really weird
# im gonna be really mad if i dont need this
static func modify_advanced_inputlist(this_list: PoolByteArray) -> PoolByteArray:
	this_list[advancedenum.DELTAFRAMES] += 1
	if Input.is_action_pressed("forward"):
		this_list[advancedenum.FORWARD] += 1
	if Input.is_action_pressed("back"):
		this_list[advancedenum.BACK] += 1
	if Input.is_action_pressed("left"):
		this_list[advancedenum.LEFT] += 1
	if Input.is_action_pressed("right"):
		this_list[advancedenum.RIGHT] += 1
	if Input.is_action_pressed("walk"):
		this_list[advancedenum.WALK] += 1
	if Input.is_action_just_pressed("jump"):
		this_list[advancedenum.jump] == 1
	if Input.is_action_pressed("crouch"):
		this_list[advancedenum.CROUCH] += 1
	if Input.is_action_pressed("shoot"):
		if this_list[advancedenum.SHOOT] == 0:
			this_list[advancedenum.SHOOT] = this_list[advancedenum.DELTAFRAMES]
	if Input.is_action_pressed("reload"):
		this_list[advancedenum.RELOAD] = 1
	if Input.is_action_pressed("zoom"):
		this_list[advancedenum.ADS] = 1
	if Input.is_action_just_pressed("lastgun"):
		this_list[advancedenum.LASTGUN] = 1
	if Input.is_action_just_pressed("gun1"):
		this_list[advancedenum.GUN1] = 1
	if Input.is_action_just_pressed("gun2"):
		this_list[advancedenum.GUN2] = 1
	if Input.is_action_just_pressed("meleeweapon"):
		this_list[advancedenum.MELEEWEAPON] = 1
	if Input.is_action_just_pressed("cyclegrenades"):
		this_list[advancedenum.CYCLEGRENADES] = 1
	if Input.is_action_just_pressed("melee"):
		this_list[advancedenum.MELEE] = 1
	if Input.is_action_just_pressed("grenade"):
		this_list[advancedenum.GRENADE] = 1
	if Input.is_action_just_pressed("drop"):
		this_list[advancedenum.DROP] = 1
	if Input.is_action_just_pressed("interact"):
		this_list[advancedenum.INTERACT] = 1
	return this_list

#static func keyboard_inputlist_to_advanced(this_list: PoolByteArray) -> PoolByteArray:
#	var new_list: PoolByteArray
#	new_list[advancedenum.DELTAFRAMES]
#	for input in this_list:
#		match input:
#			FORWARD:
#				new_list[advancedenum.FORWARD] += 1
#			BACK:
#				pass
#			LEFT:
#				pass
#			RIGHT:
#				pass
#			JUMP:
#				pass

#enum inputlistenum {FORWARD, BACK, LEFT, RIGHT, JUMP, SHOOT, RELOAD, ADS, GUN1,
#					GUN2, MELEE, CYCLEGRENADES, MELEEWEAPON, GRENADE, CROUCH,
#					WALK, DROP, INTERACT, LASTGUN}
#var inputlist: PoolByteArray
#
#var advanced_inputlist: PoolByteArray
#enum advancedenum {DELTAFRAMES, FORWARD, BACK, LEFT, RIGHT, JUMP, SHOOT, RELOAD,
#					ADS, GUN1, GUN2, MELEE, CYCLEGRENADES, MELEEWEAPON, GRENADE,
#					CROUCH, WALK, DROP, INTERACT, LASTGUN}
