extends Window

signal values_changed(parameters)

@onready var item_tree: Tree = find_child("Tree", true, false)
@onready var total_label: Label = find_child("TotalLabel", true, false)
@onready var normalize_button: Button = find_child("NormalizeButton", true, false)

func _ready() -> void:
	if item_tree:
		item_tree.columns = 2
		item_tree.set_column_title(0, "Item Type")
		item_tree.set_column_title(1, "Probability (%)")
		item_tree.set_column_titles_visible(true)
		item_tree.set_column_expand(0, true)
		item_tree.set_column_expand(1, true)
		
		item_tree.create_item()
		item_tree.hide_root = true
	_update_total_display()

func _on_add_button_pressed() -> void:
	add_item("type_" + str(_get_item_count() + 1), 25)
	_on_tree_item_edited()

func _get_item_count() -> int:
	if not item_tree or not item_tree.get_root():
		return 0
	var count := 0
	var child := item_tree.get_root().get_first_child()
	while child:
		count += 1
		child = child.get_next()
	return count

func add_item(type_name: String, value: float) -> void:
	var root := item_tree.get_root()
	var new_item := item_tree.create_item(root)
	
	new_item.set_text(0, type_name)
	new_item.set_editable(0, true)
	
	new_item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_item.set_range_config(1, 0, 100, 1) # min, max, step
	new_item.set_range(1, value) 
	new_item.set_editable(1, true)
	_update_total_display()
	
func _on_delete_button_pressed() -> void:
	var selected_item := item_tree.get_selected()
	if selected_item:
		selected_item.free()
		_on_tree_item_edited()

func _on_normalize_button_pressed() -> void:
	if not item_tree or not item_tree.get_root():
		return
	var items: Array = []
	var total: float = 0.0
	var child := item_tree.get_root().get_first_child()
	while child:
		items.append(child)
		total += child.get_range(1)
		child = child.get_next()
		
	if items.is_empty() or total <= 0.0:
		return
		
	var allocated: float = 0.0
	for i in range(items.size()):
		var it: TreeItem = items[i]
		if i == items.size() - 1:
			# Remaining fraction to guarantee exact 100%
			it.set_range(1, max(0.0, 100.0 - allocated))
		else:
			var norm: float = round((it.get_range(1) / total) * 100.0)
			it.set_range(1, norm)
			allocated += norm
			
	_on_tree_item_edited()

func _update_total_display() -> void:
	if not total_label or not item_tree or not item_tree.get_root():
		return
	var total: float = 0.0
	var child := item_tree.get_root().get_first_child()
	while child:
		total += child.get_range(1)
		child = child.get_next()
		
	if abs(total - 100.0) < 0.01:
		total_label.text = "Total: %.0f%% (Valid)" % total
		total_label.modulate = Color(0.1, 0.65, 0.2, 1.0)
		if normalize_button:
			normalize_button.disabled = true
	else:
		total_label.text = "Total: %.0f%% (Expected 100%%)" % total
		total_label.modulate = Color(0.85, 0.45, 0.1, 1.0)
		if normalize_button:
			normalize_button.disabled = false

func get_all_tree_data() -> Array:
	var results: Array = []
	var root := item_tree.get_root()
	var current_item := root.get_first_child()
	
	while current_item:
		var item_name := current_item.get_text(0)
		var item_value := current_item.get_range(1)
		results.append([item_name, item_value])
		current_item = current_item.get_next()
		
	return results

func _on_tree_item_edited() -> void:
	_update_total_display()
	var data := get_all_tree_data()
	values_changed.emit(data)
