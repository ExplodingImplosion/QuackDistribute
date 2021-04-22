extends ResourcePreloader

# for acessing the preloader, use get_resource("weapon name")

func _ready():
	
	add_resource("button font", preload("res://interface/fonts/montserrat_eb_32.tres"))
	
	#add base weapon and base dropped weapon such that placeholder base weapons,
	# etc don't need to load the base weapon more than once
	add_resource("Base Weapon", preload("res://Gameplay/Weapons/Base Weapon.tscn"))
	add_resource("Dropped Weapon", preload("res://Gameplay/Weapons/Dropped Weapon.tscn"))
	
	#add all guns and their dropped counterparts
	
	add_resource("M4", preload("res:///Gameplay/Weapons/M4/M4.tscn"))
	add_resource("Dropped M4", get_resource("Dropped Weapon"))
	
	add_resource("1911", preload("res:///Gameplay/Weapons/1911/1911.tscn"))
	add_resource("Dropped 1911", get_resource("Dropped Weapon"))
	
	add_resource("AK", preload("res:///Gameplay/Weapons/AK/AK.tscn"))
	add_resource("Dropped AK", get_resource("Dropped Weapon"))
