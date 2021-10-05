extends Container

onready var radar_image: TextureRect = $TextureRect
var center_position: Vector2
var center_pivot_offset: Vector2
var max_dist_x: int
var max_dist_y: int

func _ready():
	reset_radar_vars()

func rotate_radar(value: float):
	set_radar_rotation(radar_image.get_rotation() + value)

func set_radar_rotation(value: float):
	radar_image.set_rotation(value)

func move_radar(amount: Vector2):
	set_radar_location(radar_image.get_position() - amount)

func set_radar_location(position: Vector2):
	radar_image._set_position(Vector2(clamp_radar_position(position.x, max_dist_x), clamp_radar_position(position.y, max_dist_y)))
	radar_image.set_pivot_offset((get_radar_size() / 4) - position)

func change_radar_image(to_image: Texture):
	radar_image.set_texture(to_image)
	# this should get changed to incorporate set_radar_location
	reset_radar_vars()

func get_radar_size() -> Vector2:
	return radar_image.get_texture().get_size()

func reset_radar_vars():
	center_pivot_offset = get_radar_size() / 2
	center_position = -1 * (center_pivot_offset / 2)
	# since center_pivot_offset only gets set in the above line of code, it would
	# be feasible to use center_pivot_offset.x and .y for max_dist uses, but
	# I'm not gonna do that to make the code more understandable
	max_dist_x = center_pivot_offset.x * -1
	max_dist_y = center_pivot_offset.y * -1

func clamp_radar_position(position: float, clamp_value: float) -> float:
	return clamp(position, clamp_value, 0)
