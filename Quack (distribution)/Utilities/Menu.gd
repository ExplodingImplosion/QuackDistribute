extends Control
class_name Menu

var current_layer: Node

export var default_layer: NodePath
export var background: NodePath
export var other_exceptions: Array

func _ready():
	if default_layer:
		current_layer = get_node(default_layer)
	for item in get_children():
		if item.get_class() != "AudioStreamPlayer" && item.get_class() != "Node":
			item.hide()
	if current_layer:
		current_layer.show()
	if background:
		get_node(background).show()
	for each_exception in other_exceptions:
		var exception = get_node_or_null(each_exception)
		if exception:
			exception.show()


func _go_to_layer(to: Node) -> void:
	current_layer.hide()
	to.show()
	current_layer = to

#func _input(event):
#	if (Input.is_action_just_pressed("ui_cancel")):
#		match current_layer:
#			:
#				_go_to_layer(main)
