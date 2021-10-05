extends Container

onready var chat_log: VBoxContainer = $"Chat Container/ScrollContainer/Chat Messages"
onready var chat_scroller: ScrollContainer = $"Chat Container/ScrollContainer"
onready var background: Panel = $Background
onready var msgbox: LineEdit = $"Chat Container/Message Enterer"
#onready var scroller: VScrollBar = chat_scroller.get_node("_v_scroll")

# any attempts to call this on initialization seem to occur before the scroller
# isnt null, which is a pain in the ass, so ig we just keep the _h_scroll
# node for now
#func delete_unused() -> void:
#	# this is relatively stupid, since it just gets rid of a node that's always
#	# gonna be hidden anyway... but hey. why not lol
#	chat_scroller.get_node("_h_scroll").queue_free()

func add_chat_message(message: String) -> void:
	var this_message:= Label.new()
	chat_log.add_child(this_message)
	this_message.autowrap = true
	this_message.set_text(message)

func delete_last_chat_message() -> void:
	chat_log.get_children()[chat_log.get_child_count() - 1].queue_free()

func delete_chat_message_by_idx(idx: int) -> void:
	chat_log.get_child(idx).queue_free()

func clear_chat() -> void:
	for child in chat_log.get_children():
		child.queue_free()

func hide_background() -> void:
	background.hide()

func show_background() -> void:
	background.show()

func show_chat_log_only() -> void:
	show()
	chat_log_only()

func chat_log_only() -> void:
	if background.is_visible():
		background.hide()
	if msgbox.is_visible():
		msgbox.hide()
#	scroller.hide()

func make_children_visible() -> void:
	if !background.is_visible():
		background.show()
	if !msgbox.is_visible():
		msgbox.show()
#	scroller.show()

func show_chat_full() -> void:
	show()
	make_children_visible()
