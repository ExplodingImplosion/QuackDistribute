extends ResourcePreloader

# for acessing the preloader, use get_resource("weapon name")

func _ready():
	
	add_resource("button font", preload("res://interface/fonts/montserrat_eb_32.tres"))
	
	add_resource("Player Character", preload("res://Gameplay/Players/Player.tscn"))
	
	add_resource("Default 3D Environment", preload("res://Assets/Environments/Default 3D Environment.tres"))
	
	add_resource("Developer Console", preload("res://interface/Console.tscn"))
	
	#add base weapon and base dropped weapon such that placeholder base weapons,
	# etc don't need to load the base weapon more than once
	add_resource("Base Weapon", preload("res://Gameplay/Weapons/Base Weapon.tscn"))
	add_resource("Dropped Weapon", preload("res://Gameplay/Weapons/Dropped Weapon.tscn"))
	
	#add all guns, their dropped counterparts, and their skeleton skins
	
	add_resource("M4", preload("res:///Gameplay/Weapons/M4/M4.tscn"))
	add_resource("Dropped M4", get_resource("Dropped Weapon"))
	add_resource("M4 Skin", preload("res://Assets/Animations/Weapons/M4/M4 Skin.tres"))
	
	add_resource("1911", preload("res:///Gameplay/Weapons/1911/1911.tscn"))
	add_resource("Dropped 1911", get_resource("Dropped Weapon"))
	add_resource("1911 Skin", preload("res://Assets/Animations/Weapons/1911/1911 skin.tres"))
	
	add_resource("AK", preload("res:///Gameplay/Weapons/AK/AK.tscn"))
	add_resource("Dropped AK", get_resource("Dropped Weapon"))
	add_resource("AK Skin", preload("res://Assets/Animations/Weapons/AK/AK Skin.tres"))
	
	add_resource("Glock", preload("res://Gameplay/Weapons/Glock/Glock.tscn"))
	add_resource("Dropped Glock", get_resource("Dropped Weapon"))
	add_resource("Glock Skin", preload("res://Assets/Animations/Weapons/Glock/Glock Skin.tres"))
	
	# add all gamemodes
	add_resource("Default Gamemode", preload("res://Gamemodes/Default.tscn"))
	add_resource("3v3", preload("res://Gamemodes/3v3.tscn"))

func instance(this: String):
	return get_resource(this).instance()

func new_gun(this_gun: String = "Base Weapon") -> BaseWeapon:
	return get_resource(this_gun).instance()

func new_player() -> PlayerController:
	return get_resource("Player Character").instance()

func new_dropped_gun(this_gun: String = "Dropped Weapon") -> DroppedWeapon:
	return get_resource(this_gun).instance()
