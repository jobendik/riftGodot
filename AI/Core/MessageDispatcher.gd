# Message Dispatcher
extends RefCounted
class_name MessageDispatcher

var delayed_messages: Array[Message] = []
var current_time: float = 0.0
var entity_manager: EntityManager

func send_message(msg: Message) -> void:
	if msg.delay <= 0:
		_dispatch_message(msg)
	else:
		msg.dispatch_time = current_time + msg.delay
		delayed_messages.append(msg)
		# Keep the list sorted by dispatch time
		delayed_messages.sort_custom(func(a, b): return a.dispatch_time < b.dispatch_time)

func dispatch_delayed_messages(delta: float) -> void:
	current_time += delta
	
	while not delayed_messages.is_empty() and delayed_messages[0].dispatch_time <= current_time:
		var msg = delayed_messages.pop_front()
		_dispatch_message(msg)

func _dispatch_message(msg: Message) -> void:
	if msg.receiver and is_instance_valid(msg.receiver):
		if msg.receiver.has_method("handle_message"):
			msg.receiver.handle_message(msg)
