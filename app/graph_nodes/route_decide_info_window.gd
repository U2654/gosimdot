extends Window

signal values_changed(parameters)

@onready var item_tree: Tree = find_child("Tree", true, false)

func _ready() -> void:
	if item_tree:
		item_tree.columns = 2
		item_tree.set_column_title(0, "Item Type")
		item_tree.set_column_title(1, "Target Output Port (0 - 3)")
		item_tree.set_column_titles_visible(true)
		item_tree.set_column_expand(0, true)
		item_tree.set_column_expand(1, true)
		
		item_tree.create_item()
		item_tree.hide_root = true

func _on_add_button_pressed() -> void:
	add_item("type", 0)
	_on_tree_item_edited()

func add_item(name_str: String, value: int) -> void:
	var root := item_tree.get_root()
	var new_item := item_tree.create_item(root)
	
	new_item.set_text(0, name_str)
	new_item.set_editable(0, true)
	
	new_item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_item.set_range_config(1, 0, 3, 1) # min, max, step
	new_item.set_range(1, value) 
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
		var item_value: int = int(current_item.get_range(1))
		results[item_name] = item_value
		current_item = current_item.get_next()
		
	return results

func _on_tree_item_edited() -> void:
	var data := get_all_tree_data()
	values_changed.emit(data)
