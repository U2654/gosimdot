extends Window

signal values_changed(parameters)
signal mode_changed(toggled_on)

@onready var item_tree: Tree = find_child("Tree", true, false)
@onready var behaviour_check_box: CheckBox = find_child("BehaviourCheckBox", true, false)

func _ready() -> void:
	if item_tree:
		item_tree.columns = 2
		item_tree.set_column_title(0, "Item Type")
		item_tree.set_column_title(1, "Distribution Rule")
		item_tree.set_column_titles_visible(true)
		item_tree.set_column_expand(0, true)
		item_tree.set_column_expand(1, true)
		item_tree.create_item()
		item_tree.hide_root = true

func _on_add_button_pressed() -> void:
	add_item("type", "Constant 1.0")
	_on_tree_item_edited()

func add_item(name_str: String, params_str: String) -> void:
	var root := item_tree.get_root()
	var new_item := item_tree.create_item(root)
	
	new_item.set_text(0, name_str)
	new_item.set_editable(0, true)
	
	new_item.set_text(1, params_str)
	new_item.set_editable(1, true)
	
func _on_delete_button_pressed() -> void:
	var selected_item := item_tree.get_selected()
	if selected_item:
		selected_item.free()
		_on_tree_item_edited()

func get_all_tree_data() -> Dictionary:
	var results := {}
	var root := item_tree.get_root()
	var current_item := root.get_first_child()
	
	while current_item:
		var item_name := current_item.get_text(0)
		var item_value := current_item.get_text(1)
		results[item_name] = item_value
		current_item = current_item.get_next()
		
	return results

func _on_tree_item_edited() -> void:
	var data := get_all_tree_data()
	values_changed.emit(data)

func set_behaviour_check_box(toggle: bool) -> void:
	if behaviour_check_box:
		behaviour_check_box.button_pressed = toggle

func _on_behaviour_check_box_toggled(toggled_on: bool) -> void:
	mode_changed.emit(toggled_on)
