extends Container

var event_list: Array

# weapons/device/whatever the fuck enum
enum {BASEWEAPON, FALLDAMAGE, M4, _1911, AK}
# event enum
enum {KILL, HEADSHOT, WALLBANG, HEADSHOT_WALLBANG}
# relationship enum
enum {SELFENEMY, SELFSELF, SELFFRIENDLY, FRIENDLYENEMY, FRIENDLYSELF,
		FRIENDLYFRIENDLY, ENEMYENEMY, ENEMYSELF, ENEMYFRIENDLY}

# color consts

# half-transparent yellow
const selfpanelcolor: Color = Color( 1.0, 1.0, 0.0, 0.5 )
# half-transparent aquamarine
const friendlypanelcolor: Color = Color( 0.5, 1, 0.83, 0.5 )
# half-transparent lightgray
const neutralpanelcolor: Color = Color( 0.83, 0.83, 0.83, 0.5 )
# half-transparent maroon
const enemypanelcolor: Color = Color( 0.69, 0.19, 0.38, 0.5 )

const selftextcolor: Color = Color.yellow
const friendlytextcolor: Color = Color.yellowgreen
const neutraltextcolor: Color = Color.white
const enemytextcolor: Color = Color.maroon

# darkish gray
const fontshadowcolor: Color = Color("252525")

# size consts that the killfeed event hboxcontainers and background rects will use
const eventUIsize := Vector2(400,16)

func _ready():
	pass

#  - device_ID is what weapon/device someone used
#  - event_ID is something like a wallbang, a headshot, etc
#    THE EVENT ID VARIABLE WAS ORIGINALLY CALLED event_idx, and idk why. if it
#    turns out that its better named as event_idx, then hit that ctrl+r ;)
#  - relationship is basically what the killfeed event means in relation to the player,
#    (they killed someone, teammate killed someone, etc)
func add_event(inflictor_username: String, device_ID: int, event_ID: int, target_username: String, relationship: int) -> void:
	var this_event: killfeed_event = killfeed_event.new(self, inflictor_username, device_ID, event_ID, target_username, relationship)

class killfeed_event:
	var event_container := HBoxContainer.new()
	var inflictor_label := Label.new()
	var device_icon := TextureRect.new()
	var event_icon := TextureRect.new()
	var target_label := Label.new()
	var background_rect := ColorRect.new()
	
	static func apply_ui_size(variant: Control) -> void:
		variant.set_custom_minimum_size(eventUIsize)
	
	static func apply_font_shadow(variant: Label) -> void:
		variant.set("custom_colors/font_color_shadow", fontshadowcolor)
	
	func add_children() -> void:
		event_container.add_child(inflictor_label)
		event_container.add_child(device_icon)
		event_container.add_child(event_icon)
		event_container.add_child(target_label)
	
	func setup_hbox(inflictor_username: String, target_username: String) -> void:
#		this_event.set_custom_minimum_size(eventUIsize) is functionally the same
		apply_ui_size(event_container)
		event_container.set_alignment(BoxContainer.ALIGN_CENTER)
		
	
	func get_panel_color_based_on_relationship(relationship: int) -> Color:
		if relationship < FRIENDLYENEMY:
			return selfpanelcolor
		elif relationship < ENEMYENEMY:
			return friendlypanelcolor
		else:
			return enemypanelcolor
	
	func apply_background_color_based_on_relationship(relationship: int) -> void:
		background_rect.set_frame_color(get_panel_color_based_on_relationship(relationship))
	
	func setup_background_rect(relationship: int) -> void:
		apply_ui_size(background_rect)
		apply_background_color_based_on_relationship(relationship)
	
	
	func setup_usernames(relationship: int) -> void:
		setup_inflictor(relationship)
		setup_target(relationship)
	
	func setup_inflictor(relationship: int) -> void:
		apply_font_shadow(inflictor_label)
		apply_inflictor_color_based_on_relationship(relationship)
	
	func setup_target(relationship: int) -> void:
		apply_font_shadow(target_label)
		apply_target_color_based_on_relationship(relationship)
	
	func apply_inflictor_color_based_on_relationship(relationship: int) -> void:
		pass
	
	func apply_target_color_based_on_relationship(relationship: int) -> void:
		pass
	
	func _init(parent: Container, inflictor_username: String, device_ID: int, event_ID: int, target_username: String, relationship: int):
		parent.add_child(background_rect)
		setup_background_rect(relationship)
		parent.add_child(event_container)
		add_children()
	
