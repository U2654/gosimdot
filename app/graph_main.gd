extends GraphEdit

func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	connect_node(from_node, from_port, to_node, to_port)
	var source = get_node(str(from_node))
	var target = get_node(str(to_node))
	if target.get_input_port_type(to_port) == 1:
		if (source.informs_output):
			source.connect_output(from_port, target, to_port)

		if (target.informs_input):
			target.connect_input(to_port, source, from_port)
	elif target.get_input_port_type(to_port) == 2:
		target.attach_decide(source)
	elif target.get_input_port_type(to_port) == 3:
		target.attach_resource(source)
	_notify_status()

func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	disconnect_node(from_node, from_port, to_node, to_port)
	var source = get_node(str(from_node))
	var target = get_node(str(to_node))

	if target.get_input_port_type(to_port) == 1:
		if (source.informs_output):
			source.disconnect_output(from_port, target, to_port)

		if (target.informs_input):
			target.disconnect_input(to_port, source, from_port)

	elif target.get_input_port_type(to_port) == 2:
		target.detach_decide(source)
	elif target.get_input_port_type(to_port) == 3:
		target.detach_resource(source)
	_notify_status()

func _notify_status() -> void:
	var sb = get_parent().find_child("StatusBar")
	if sb and sb.has_method("refresh_status"):
		sb.refresh_status()
