class_name DecideGraphNode
extends GraphNode

@onready var info_button := Button.new()
@onready var close_button := Button.new()

@export var info_window_scene : PackedScene
@onready var info_window : Window

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

var _window_placed := false

func get_node_type_name() -> String:
	return "Decision Node"

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
	
func set_load_data(data: Variant):
	pass
	
