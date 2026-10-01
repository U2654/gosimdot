extends PanelContainer

@onready var nodes_label: Label = find_child("NodesLabel", true, false)
@onready var conns_label: Label = find_child("ConnsLabel", true, false)
@onready var events_label: Label = find_child("EventsLabel", true, false)
@onready var zoom_label: Label = find_child("ZoomLabel", true, false)

func _ready() -> void:
	refresh_status()

func refresh_status() -> void:
	var ge = get_parent().find_child("GraphEdit")
	var sim = get_parent().find_child("SimulationManager")
	
	if ge and nodes_label:
		var node_count := 0
		for child in ge.get_children():
			if child is GraphNode:
				node_count += 1
		nodes_label.text = "Nodes: %d" % node_count
		
	if ge and conns_label:
		conns_label.text = "Connections: %d" % ge.get_connection_list().size()
		
	if ge and zoom_label:
		zoom_label.text = "Zoom: %.0f%%" % (ge.zoom * 100.0)
		
	if sim and events_label:
		events_label.text = "Events in Queue: %d" % sim.event_list.size()

func _on_reset_view_pressed() -> void:
	var ge = get_parent().find_child("GraphEdit")
	if ge:
		ge.scroll_offset = Vector2.ZERO
		ge.zoom = 1.0
		refresh_status()

func _on_toggle_minimap_pressed() -> void:
	var ge = get_parent().find_child("GraphEdit")
	if ge:
		ge.minimap_enabled = !ge.minimap_enabled
