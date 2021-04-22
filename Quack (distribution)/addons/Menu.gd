extends Control
class_name Menu


var current_layer: Node


func _ready():
#	current_layer = main
	for item in get_children():
		item.hide()


func _go_to_layer(to: Node) -> void:
	current_layer.hide()
	to.show()
	current_layer = to

#func _input(event):
#	if (Input.is_action_just_pressed("ui_cancel")):
#		match current_layer:
#			:
#				_go_to_layer(main)
