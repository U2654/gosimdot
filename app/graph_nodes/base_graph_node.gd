class_name BaseGraphNode
extends GraphNode

@onready var info_button := Button.new()
@onready var close_button := Button.new()

@export var info_window_scene : PackedScene
@onready var info_window : Window

var title_edit := LineEdit.new()
var title_label: Label = null
var _saved_title: String = ""
var _is_editing_title: bool = false
var _window_placed := false

func _ready() -> void:
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
		_setup_title_editor()
	
	info_button.pressed.connect(_on_info_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)

	if info_window_scene:
		info_window = info_window_scene.instantiate()
		info_window.visible = false
		add_child(info_window)
		info_window.close_requested.connect(_on_info_window_close_requested)
		setup_info_window()

func _setup_title_editor() -> void:
	var titlebar := get_titlebar_hbox()
	if not titlebar:
		return
	
	titlebar.mouse_filter = Control.MOUSE_FILTER_PASS
	titlebar.gui_input.connect(_on_titlebar_gui_input)
	
	for child in titlebar.get_children():
		if child is Label:
			title_label = child
			title_label.mouse_filter = Control.MOUSE_FILTER_PASS
			title_label.tooltip_text = "Double-click to rename"
			title_label.gui_input.connect(_on_titlebar_gui_input)
			break
	
	title_edit.visible = false
	title_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_edit.custom_minimum_size = Vector2(60, 22)
	title_edit.placeholder_text = "Node name..."
	title_edit.text_submitted.connect(_on_title_submitted)
	title_edit.focus_exited.connect(_on_title_focus_exited)
	title_edit.gui_input.connect(_on_title_edit_gui_input)
	titlebar.add_child(title_edit)
	if title_label:
		titlebar.move_child(title_edit, title_label.get_index() + 1)
	else:
		titlebar.move_child(title_edit, 0)

func _on_titlebar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		_start_title_edit()
		accept_event()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		var tb = get_titlebar_hbox()
		if tb and event.position.y <= tb.size.y + 10:
			_start_title_edit()
			accept_event()

func _start_title_edit() -> void:
	if _is_editing_title:
		return
	_is_editing_title = true
	_saved_title = title
	title_edit.text = title
	if title_label:
		title_label.visible = false
	title_edit.visible = true
	title_edit.grab_focus()
	title_edit.call_deferred("select_all")

func _on_title_submitted(_text: String) -> void:
	_finish_title_edit(true)

func _on_title_focus_exited() -> void:
	_finish_title_edit(true)

func _on_title_edit_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_finish_title_edit(false)
			get_viewport().set_input_as_handled()

func _finish_title_edit(commit: bool) -> void:
	if not _is_editing_title:
		return
	_is_editing_title = false
	if commit:
		var new_text := title_edit.text.strip_edges()
		if new_text != "":
			title = new_text
		else:
			title = _saved_title
	else:
		title = _saved_title
	
	title_edit.visible = false
	if title_label:
		title_label.visible = true
	update_window_title()

func get_node_type_name() -> String:
	return "Node"

func update_window_title() -> void:
	if info_window:
		var display_title: String = title if title != "" else String(name)
		info_window.title = "%s — %s" % [display_title, get_node_type_name()]

func setup_info_window() -> void:
	update_window_title()

func _on_info_window_close_requested() -> void:
	if info_window:
		info_window.hide()

func _on_info_button_pressed() -> void:
	if not info_window:
		return
	update_window_title()
	if not _window_placed:
		_position_info_window()
		_window_placed = true
	info_window.show()
	info_window.grab_focus()

func _position_info_window() -> void:
	if not info_window:
		return
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

func _on_close_button_pressed() -> void:
	queue_free()

### serialize stuff
func get_save_data() -> Variant:
	return null

func set_load_data(_data: Variant) -> void:
	pass
