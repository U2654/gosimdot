class_name SimGraphNode
extends GraphNode

@onready var info_button := Button.new()
@onready var close_button := Button.new()

@export var info_window_scene : PackedScene
@onready var info_window : Window

var informs_output = true
var informs_input = false

func _ready():
	custom_minimum_size = Vector2(160, 65)
	
	info_button.text = "ℹ"
	info_button.tooltip_text = "Configure & Inspect"
	info_button.custom_minimum_size = Vector2(22, 20)
	info_button.focus_mode = Control.FOCUS_NONE
	
	close_button.text = "✕"
	close_button.tooltip_text = "Delete Node"
	close_button.custom_minimum_size = Vector2(22, 20)
	close_button.focus_mode = Control.FOCUS_NONE
	
	var titlebar := get_titlebar_hbox()
	if titlebar:
		titlebar.add_theme_constant_override("separation", 4)
		titlebar.add_child(info_button)
		titlebar.add_child(close_button)
	
	info_button.pressed.connect(_on_info_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)

	info_window = info_window_scene.instantiate()
	info_window.visible = false
	add_child(info_window)
	info_window.close_requested.connect(_on_info_window_close_requested)
	setup_info_window()

	create_logic()

var _window_placed := false

func get_node_type_name() -> String:
	return "Simulation Node"

func update_window_title():
	if info_window:
		var display_title = title if title != "" else name
		info_window.title = "%s — %s" % [display_title, get_node_type_name()]

func setup_info_window():
	update_window_title()

func _on_info_window_close_requested():
	info_window.hide()

func _on_info_button_pressed():
	update_window_title()
	if not _window_placed:
		_position_info_window()
		_window_placed = true
	info_window.show()
	info_window.grab_focus()

func _position_info_window():
	var vp = get_viewport()
	if not vp:
		return
	var vp_size = vp.get_visible_rect().size
	var target_x = int(global_position.x + size.x + 20)
	var target_y = int(global_position.y)
	if target_x + info_window.size.x > vp_size.x:
		target_x = max(10, int(global_position.x - info_window.size.x - 20))
	if target_y + info_window.size.y > vp_size.y:
		target_y = max(10, int(vp_size.y - info_window.size.y - 20))
	info_window.position = Vector2i(target_x, target_y)

func _on_close_button_pressed():
	queue_free()
	
### serialize stuff
func get_save_data() -> Variant:
	return null
	
### logic
signal output_ready_p0(node: SimGraphNode, own_port: int, other_port: int)
signal output_ready_p1(node: SimGraphNode, own_port: int, other_port: int)
signal output_ready_p2(node: SimGraphNode, own_port: int, other_port: int)
signal output_ready_p3(node: SimGraphNode, own_port: int, other_port: int)
signal input_ready_p0(node: SimGraphNode, own_port: int, other_port: int)
signal input_ready_p1(node: SimGraphNode, own_port: int, other_port: int)
signal input_ready_p2(node: SimGraphNode, own_port: int, other_port: int)
signal input_ready_p3(node: SimGraphNode, own_port: int, other_port: int)

@onready var input_ready = [input_ready_p0, input_ready_p1, input_ready_p2, input_ready_p3]
@onready var output_ready = [output_ready_p0, output_ready_p1, output_ready_p2, output_ready_p3]


func connect_input(own_port: int, other_node: SimGraphNode, other_port: int):
	input_ready[own_port].connect(other_node.on_output_ready.bind(other_port))

func disconnect_input(own_port: int, other_node: SimGraphNode, other_port: int):
	input_ready[own_port].disconnect(other_node.on_output_ready.bind(other_port))

func connect_output(own_port: int, other_node: SimGraphNode, other_port: int):
	output_ready[own_port].connect(other_node.on_input_ready.bind(other_port))

func disconnect_output(own_port: int, other_node: SimGraphNode, other_port: int):
	output_ready[own_port].disconnect(other_node.on_input_ready.bind(other_port))

	
func on_input_ready(_node: SimGraphNode, _other_port: int, _own_port : int):
	pass

func on_output_ready(_node: SimGraphNode, _other_port: int, _own_port: int):
	pass

func take_output(_port: int) -> Variant:
	return null

func create_logic():
	pass
	
func run_logic():
	pass
	
func reset():
	pass
