extends MenuBar

const NETWORKS_DIR := "res://app/networks/"
const ABOUT_DIALOG_SCENE := preload("res://app/gui/about_dialog.tscn")

var about_dialog: AcceptDialog = null
var current_file_path: String = ""

const EXAMPLES := [
	{"name": "Parallel Servers", "path": "res://app/networks/parallel_servers.json"},
	{"name": "Router 2-Way", "path": "res://app/networks/router_2way.json"},
	{"name": "Router 3-Way", "path": "res://app/networks/router_3way.json"},
	{"name": "Three Processing Stages", "path": "res://app/networks/three_processing_stages.json"},
	{"name": "Resource Pool Demo", "path": "res://app/networks/resource.json"},
	{"name": "Typed Service Delay", "path": "res://app/networks/typed_service_delay.json"},
	{"name": "Demo Network", "path": "res://app/networks/demo.json"},
	{"name": "Bank Teller", "path": "res://app/networks/bank_teller.json"}
]

func _ready() -> void:
	var em = find_child("ExamplesMenu", true, false)
	if em and em is PopupMenu:
		em.clear()
		for i in range(EXAMPLES.size()):
			em.add_item(EXAMPLES[i]["name"], i)

func _on_gosimdot_menu_id_pressed(id: int) -> void:
	match id:
		1:
			show_about_dialog()
		2:
			get_tree().quit()

func _on_file_menu_id_pressed(id: int) -> void:
	match id:
		1:
			new_file()
		2:
			load_file()
		3:
			save_file()
		4:
			save_file_as()
		_:
			pass

func show_about_dialog() -> void:
	if not about_dialog:
		about_dialog = ABOUT_DIALOG_SCENE.instantiate()
		add_child(about_dialog)
	about_dialog.popup_centered()

func _on_examples_menu_id_pressed(id: int) -> void:
	if id >= 0 and id < EXAMPLES.size():
		load_graph(EXAMPLES[id]["path"])

func _on_view_menu_id_pressed(id: int) -> void:
	var ge = get_parent().find_child("GraphEdit")
	if not ge:
		return
	match id:
		0:
			ge.scroll_offset = Vector2.ZERO
			ge.zoom = 1.0
		1:
			ge.minimap_enabled = !ge.minimap_enabled
		2:
			ge.clear_connections()

func new_file():
	current_file_path = ""
	clear_graph()

func load_file():
	var fd = get_parent().find_child("FileDialog")
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.current_dir = NETWORKS_DIR
	fd.title = "Open a Graph"
	fd.popup_centered()
	
func save_file():
	if current_file_path != "":
		save_graph(current_file_path)
	else:
		save_file_as()

func save_file_as():
	var fd = get_parent().find_child("FileDialog")
	fd.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	fd.current_dir = NETWORKS_DIR
	fd.title = "Save your Graph As..."
	fd.popup_centered()
	
func _on_file_dialog_file_selected(path: String):
	var fd = get_parent().find_child("FileDialog")
	if fd.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		save_graph(path)
	else:
		load_graph(path)
	
func get_node_prefix(scene_path: String) -> String:
	if "source_decide" in scene_path:
		return "SD"
	elif "delay_decide" in scene_path:
		return "DD"
	elif "route_decide" in scene_path:
		return "RD"
	elif "resource" in scene_path:
		return "Re"
	elif "source" in scene_path:
		return "So"
	elif "sink" in scene_path:
		return "Si"
	elif "queue" in scene_path:
		return "Qu"
	elif "delay" in scene_path:
		return "De"
	elif "route" in scene_path:
		return "Ro"
	return "No"

func clear_graph():
	var sim := get_node("/root/Main/SimulationManager")
	sim.reset()
	var top_bar = get_parent().find_child("TopBar")
	if top_bar:
		top_bar.node_counter = 1
		if top_bar.has_method("update_time_label"):
			top_bar.update_time_label()

	var ge = get_parent().find_child("GraphEdit")
	ge.clear_connections()
	for child in ge.get_children():
		if child is GraphNode:
			child.queue_free()
	await get_tree().process_frame 
	
func load_graph(path: String):
	if not FileAccess.file_exists(path):
		push_warning("File does not exist: %s" % path)
		return

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to open file for reading: %s (error: %d)" % [path, FileAccess.get_open_error()])
		return
	var json_string = file.get_as_text()
	var data = JSON.parse_string(json_string)

	if data == null:
		return

	current_file_path = path

	await clear_graph()
	var ge = get_parent().find_child("GraphEdit")
	if ge:
		ge.scroll_offset = Vector2.ZERO
		ge.zoom = 1.0
	var i = 0
	for node_data in data["nodes"]:
		var node_scene = load(node_data["type"])
		var new_node = node_scene.instantiate() 
		new_node.name = node_data["name"]
		var prefix = get_node_prefix(node_data["type"])
		var saved_title = str(node_data.get("title", ""))
		if saved_title != "" and not saved_title.is_valid_int():
			new_node.title = saved_title
		else:
			var suffix = saved_title if saved_title != "" else str(i)
			new_node.title = prefix + suffix
		i += 1
		ge.add_child(new_node)
		new_node.position_offset = Vector2(node_data["pos_x"], node_data["pos_y"])
		if new_node.has_method("set_load_data") and node_data.get("custom_data") != null:
			new_node.set_load_data(node_data["custom_data"])

	var top_bar = get_parent().find_child("TopBar")
	if top_bar:
		top_bar.node_counter = i + 1
		if top_bar.has_method("update_time_label"):
			top_bar.update_time_label()

	await get_tree().process_frame 
	
	for conn in data["connections"]:
		ge._on_connection_request(
			conn["from_node"], conn["from_port"], 
			conn["to_node"], conn["to_port"]
		)
	
func save_graph(path: String):
	var data = {
 		"nodes": [],
		"connections": []
	}
	
	var ge = get_parent().find_child("GraphEdit")
	data.connections = ge.get_connection_list()
	
	for child in ge.get_children():
		if child is GraphNode:
			var node_info = {
				"name": child.name,
				"title": child.title,
				"type": child.scene_file_path, 
				"pos_x": child.position_offset.x,
				"pos_y": child.position_offset.y,
				"custom_data": child.get_save_data()
			}
			data["nodes"].append(node_info)
   
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		current_file_path = path
	else:
		push_error("Failed to open file for writing: %s (error: %d)" % [path, FileAccess.get_open_error()])
