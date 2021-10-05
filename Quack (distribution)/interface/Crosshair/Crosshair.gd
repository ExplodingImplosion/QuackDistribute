extends Control

#references
onready var top = $Top
onready var bottom = $Bottom
onready var left = $Left
onready var right = $Right
onready var dot = $Dot

#crosshair color values
onready var color = settings.get_setting("Crosshair Settings", "Color")
onready var dot_color = settings.get_setting("Crosshair Settings", "DotColor")

#crosshair dimensions/spacing values
onready var length = settings.get_setting("Crosshair Settings", "Length")
onready var width = settings.get_setting("Crosshair Settings", "Width")
onready var opacity = settings.get_setting("Crosshair Settings", "Opacity")
onready var gap = settings.get_setting("Crosshair Settings", "Gap")

#border values
onready var border = settings.get_setting("Crosshair Settings", "Border")
onready var border_size = settings.get_setting("Crosshair Settings", "BorderSize")
onready var border_opacity = settings.get_setting("Crosshair Settings", "BorderOpacity")

#dot values
onready var use_dot = settings.get_setting("Crosshair Settings", "Dot")
onready var dot_opacity = settings.get_setting("Crosshair Settings", "DotOpacity")
onready var dot_size = settings.get_setting("Crosshair Settings", "DotSize")
#currently doesn't do anything. im lazy :p
onready var dot_border = settings.get_setting("Crosshair Settings", "DotBorder")

#array of crosshair hairs
onready var crosshair = [top, bottom, left, right]

func _ready():
	set_position(Vector2(960,540))
	build_crosshair()

func build_crosshair():
	dot.set_position(Vector2(-1,-1))
	for obj in crosshair:
		obj.set_custom_minimum_size(Vector2(width, length))
		obj._set_size(Vector2(width, length))
		obj.set_frame_color(Color(color.r, color.g, color.b, opacity))
	if border == true:
		for obj in crosshair:
			obj.get_child(0).set_position(Vector2(-border_size, -border_size))
			obj.get_child(1).set_position(Vector2(-border_size, length))
			obj.get_child(2).set_position(Vector2(-border_size, 0))
			obj.get_child(3).set_position(Vector2(width, 0))
			for child in obj.get_children():
				child.set_frame_color(Color(0,0,0,border_opacity))
				child.set_visible(true)
				if child.get_index() < 2:
					child.set_custom_minimum_size(Vector2(width + border_size*2, border_size))
					child._set_size(Vector2(width + border_size*2, border_size))
				else:
					child.set_custom_minimum_size(Vector2(border_size, length))
					child._set_size(Vector2(border_size, length))
	else:
		for obj in crosshair:
			for child in obj.get_children():
				child.set_visible(false)
	
	top.set_position(Vector2(-width/2, -1 * (length + gap*2)))
	bottom.set_position(Vector2(width/2, length + gap*2))
	left.set_position(Vector2(-gap*2,-width/2))
	right.set_position(Vector2(gap*2,width/2))
	
	
	if use_dot == true:
		dot.set_visible(true)
		dot.set_frame_color(Color(dot_color.r, dot_color.g, dot_color.b, dot_opacity))
		dot.set_custom_minimum_size(Vector2(dot_size * 2,dot_size * 2))
		dot._set_size(Vector2(dot_size * 2,dot_size * 2))
		dot.set_position(Vector2(dot_size * -1, dot_size * -1))
		# tbf this is how it should be done for the normal crosshairs, too
		if dot_border == true:
			for child in dot.get_children():
				child.set_frame_color(Color(0,0,0,border_opacity))
				child.set_visible(true)
				child.set_custom_minimum_size(Vector2((dot_size + border_size) * 2, (dot_size + border_size) * 2))
				child._set_size(child.get_custom_minimum_size())
				print(child.get_size())
				child.set_position(Vector2(border_size * -1, border_size * -1))
		else:
			dot.get_child(0).set_visible(false)
	else:
		dot.set_visible(false)
		dot.get_child(0).set_visible(false)


#this code is absolute dogshit, but I'm doing this with like 4 hours of sleep, and I'm out of fucks to give right now
func rebuild_crosshair():
	
	#hahahahaha i hacked this so bad lmaooooooooooooooooooooooooooooooooooooooooooooooo
	
	#crosshair color values
	color = settings.get_setting("Crosshair Settings", "Color")
	dot_color = settings.get_setting("Crosshair Settings", "DotColor")
	
	#crosshair dimensions/spacing values
	length = settings.get_setting("Crosshair Settings", "Length")
	width = settings.get_setting("Crosshair Settings", "Width")
	opacity = settings.get_setting("Crosshair Settings", "Opacity")
	gap = settings.get_setting("Crosshair Settings", "Gap")
	
	#border values
	border = settings.get_setting("Crosshair Settings", "Border")
	border_size = settings.get_setting("Crosshair Settings", "BorderSize")
	border_opacity = settings.get_setting("Crosshair Settings", "BorderOpacity")
	
	#dot values
	use_dot = settings.get_setting("Crosshair Settings", "Dot")
	dot_opacity = settings.get_setting("Crosshair Settings", "DotOpacity")
	dot_size = settings.get_setting("Crosshair Settings", "DotSize")
	#currently doesn't do anything. im lazy :p
	dot_border = settings.get_setting("Crosshair Settings", "DotBorder")
	build_crosshair()
