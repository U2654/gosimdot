extends PanelContainer

enum ButtonType {
	SOURCE = 1,
	SINK = 2,
	QUEUE = 3,
	DELAY = 4,
	ROUTE = 5,
	SOURCE_DECIDE = 11,
	DELAY_DECIDE = 14, 
	ROUTE_DECIDE = 15,
	RESOURCE = 16
}

var source_node = load("res://app/graph_nodes/source_graph_node.tscn")
var sink_node = load("res://app/graph_nodes/sink_graph_node.tscn")
var queue_node = load("res://app/graph_nodes/queue_graph_node.tscn")
var delay_node = load("res://app/graph_nodes/delay_graph_node.tscn")
var route_node = load("res://app/graph_nodes/route_graph_node.tscn")
var source_decide_node = load("res://app/graph_nodes/source_decide_graph_node.tscn")
var delay_decide_node = load("res://app/graph_nodes/delay_decide_graph_node.tscn")
var route_decide_node = load("res://app/graph_nodes/route_decide_graph_node.tscn")
var resource_node = load("res://app/graph_nodes/resource_graph_node.tscn")
var node_counter = 1

var sim : SimulationManager
var is_playing: bool = false
var play_timer: Timer

@onready var time_label: Label = find_child("TimeLabel", true, false)
@onready var state_badge: Label = find_child("StateBadge", true, false)
@onready var play_button: Button = find_child("PlayButton", true, false)
@onready var pause_button: Button = find_child("PauseButton", true, false)
@onready var run_duration_spin_box: SpinBox = find_child("RunDurationSpinBox", true, false)
@onready var max_steps_edit: LineEdit = find_child("MaxStepsLineEdit", true, false)
@onready var speed_option: OptionButton = find_child("SpeedOptionButton", true, false)

func _ready() -> void:
	sim = get_node("../SimulationManager")
	
	play_timer = Timer.new()
	play_timer.wait_time = 0.1
	play_timer.one_shot = false
	play_timer.timeout.connect(_on_play_timer_tick)
	add_child(play_timer)
	
	if speed_option:
		speed_option.clear()
		speed_option.add_item("1x (Normal)")
		speed_option.add_item("2x (Fast)")
		speed_option.add_item("5x (Rapid)")
		speed_option.add_item("Max Speed")
		speed_option.item_selected.connect(_on_speed_changed)
		speed_option.selected = 0
		
	var decide_menu = find_child("DecideMenuButton", true, false)
	if decide_menu and decide_menu is MenuButton:
		var popup = decide_menu.get_popup()
		popup.clear()
		popup.add_item("Source Probabilities", ButtonType.SOURCE_DECIDE)
		popup.add_item("Delay Rules", ButtonType.DELAY_DECIDE)
		popup.add_item("Routing Table", ButtonType.ROUTE_DECIDE)
		popup.id_pressed.connect(_on_decide_menu_id_pressed)
		
	update_time_label()

func _on_decide_menu_id_pressed(id: int) -> void:
	_on_an_add_button_pressed(id)

func _on_speed_changed(index: int) -> void:
	match index:
		0: play_timer.wait_time = 0.1
		1: play_timer.wait_time = 0.05
		2: play_timer.wait_time = 0.02
		3: play_timer.wait_time = 0.005
		_: play_timer.wait_time = 0.1

func _on_an_add_button_pressed(id : int) -> void:
	var node
	var prefix : String = ""
	match id:
		ButtonType.SOURCE:
			node = source_node.instantiate()
			node.name = "SourceNode"
			prefix = "So"
		ButtonType.SINK:
			node = sink_node.instantiate()
			node.name = "SinkNode"
			prefix = "Si"
		ButtonType.QUEUE:
			node = queue_node.instantiate()
			node.name = "QueueNode"
			prefix = "Qu"
		ButtonType.DELAY:
			node = delay_node.instantiate()
			node.name = "DelayNode"
			prefix = "De"
		ButtonType.ROUTE:
			node = route_node.instantiate()
			node.name = "RouteNode"
			prefix = "Ro"
		ButtonType.SOURCE_DECIDE:
			node = source_decide_node.instantiate()
			node.name = "SourceDecide"
			prefix = "SD"
		ButtonType.DELAY_DECIDE:
			node = delay_decide_node.instantiate()
			node.name = "DelayDecide"
			prefix = "DD"
		ButtonType.ROUTE_DECIDE:
			node = route_decide_node.instantiate()
			node.name = "RouteDecide"
			prefix = "RD"
		ButtonType.RESOURCE:
			node = resource_node.instantiate()
			node.name = "ResourceNode"
			prefix = "Re"
		_:
			return
			
	node.position_offset = Vector2i(80, 80) * (node_counter % 12 + 1)
	node.title = prefix + str(node_counter)
	node.name += str(node_counter)
	var graph = get_node("../GraphEdit")
	graph.add_child(node)
	node_counter += 1
	_notify_status_update()

func sim_step_graph() -> bool:
	var graph = get_node("../GraphEdit")
	var connection_list = graph.get_connection_list()
	for connection in connection_list:
		var from_node_path = NodePath(connection["from_node"])
		var from_node = graph.get_node_or_null(from_node_path)
		if not from_node:
			continue
		var from_port = connection["from_port"]
		var from_type = from_node.get_output_port_type(from_port)
		if (sim.sim_clock == 0 and from_type == 1):
			from_node.run_logic()
	return sim.step()

func reset_sim_graph():
	var graph = get_node("../GraphEdit")
	for child in graph.get_children():
		if child is SimGraphNode or child is DecideGraphNode:
			child.reset()

func _on_step_button_pressed() -> void:
	_stop_playback()
	if not sim.event_list.is_empty() and sim.event_list.front().time > sim.run_duration:
		sim.run_duration = sim.event_list.front().time
		if max_steps_edit:
			max_steps_edit.text = str(sim.run_duration)
	var has_more := sim_step_graph()
	update_time_label()
	if not has_more and state_badge:
		state_badge.text = "● FINISHED"
		state_badge.modulate = Color(0.2, 0.5, 0.9, 1.0)
	
func _on_reset_button_pressed() -> void:
	_stop_playback()
	sim.reset()
	reset_sim_graph()
	update_time_label()
	if state_badge:
		state_badge.text = "● IDLE"
		state_badge.modulate = Color(0.5, 0.55, 0.6, 1.0)

func _on_play_button_pressed() -> void:
	if not is_playing:
		_start_playback()

func _on_pause_button_pressed() -> void:
	if is_playing:
		_stop_playback()

func _start_playback() -> void:
	is_playing = true
	if state_badge:
		state_badge.text = "● RUNNING"
		state_badge.modulate = Color(0.1, 0.75, 0.3, 1.0)
	play_timer.start()

func _stop_playback() -> void:
	is_playing = false
	if state_badge and sim.sim_clock > 0:
		state_badge.text = "● PAUSED"
		state_badge.modulate = Color(0.9, 0.6, 0.1, 1.0)
	play_timer.stop()

func _on_play_timer_tick() -> void:
	var requested_time = max_steps_edit.text.to_float() if max_steps_edit else 1000.0
	if sim.sim_clock >= requested_time:
		_stop_playback()
		if state_badge:
			state_badge.text = "● AT TARGET"
			state_badge.modulate = Color(0.2, 0.5, 0.9, 1.0)
		return
		
	var has_more := sim_step_graph()
	update_time_label()
	
	if not has_more:
		_stop_playback()
		if state_badge:
			state_badge.text = "● FINISHED"
			state_badge.modulate = Color(0.2, 0.5, 0.9, 1.0)

func _on_run_button_pressed() -> void:
	_stop_playback()
	if max_steps_edit:
		var requested_time = max_steps_edit.text.to_float()
		if sim.sim_clock >= requested_time:
			max_steps_edit.grab_focus()
			max_steps_edit.select_all()
			return
		sim.run_duration = requested_time
	while sim.sim_clock <= sim.run_duration:
		if not sim_step_graph():
			break
	update_time_label()
	
func update_time_label():
	if time_label:
		time_label.text = "Time: %.2f s" % sim.sim_clock
	_notify_status_update()
	
func _on_max_steps_line_edit_text_submitted(new_text: String) -> void:
	sim.run_duration = new_text.to_float()

func _on_run_next_button_pressed() -> void:
	_stop_playback()
	var duration: float = run_duration_spin_box.value if run_duration_spin_box else 10.0
	sim.run_duration += duration
	if max_steps_edit:
		max_steps_edit.text = str(sim.run_duration)
	while sim.sim_clock <= sim.run_duration:
		if not sim_step_graph():
			break
	update_time_label()

func _notify_status_update() -> void:
	var status_bar = get_parent().find_child("StatusBar")
	if status_bar and status_bar.has_method("refresh_status"):
		status_bar.refresh_status()
