extends Window

@onready var count_value: Label = $MarginContainer/VBoxContainer/MetricsCard/VBoxContainer/GridContainer/CountValue
@onready var peak_value: Label = $MarginContainer/VBoxContainer/MetricsCard/VBoxContainer/GridContainer/PeakValue
@onready var enqueued_value: Label = $MarginContainer/VBoxContainer/MetricsCard/VBoxContainer/GridContainer/EnqueuedValue
@onready var dequeued_value: Label = $MarginContainer/VBoxContainer/MetricsCard/VBoxContainer/GridContainer/DequeuedValue
@onready var progress_bar: ProgressBar = $MarginContainer/VBoxContainer/MetricsCard/VBoxContainer/ProgressBar
@onready var items_tree: Tree = $MarginContainer/VBoxContainer/QueuePanel/VBoxContainer/Tree
@onready var empty_label: Label = $MarginContainer/VBoxContainer/QueuePanel/VBoxContainer/EmptyLabel
@onready var legacy_label: Label = $Label

func _ready() -> void:
	if items_tree:
		items_tree.columns = 3
		items_tree.set_column_title(0, "Item ID")
		items_tree.set_column_title(1, "Type")
		items_tree.set_column_title(2, "Created At")
		items_tree.set_column_titles_visible(true)
		items_tree.create_item()
		items_tree.hide_root = true

func update_stats(current_count: int, peak_count: int, total_enqueued: int, total_dequeued: int, items: Array) -> void:
	if count_value:
		count_value.text = str(current_count)
	if peak_value:
		peak_value.text = str(peak_count)
	if enqueued_value:
		enqueued_value.text = str(total_enqueued)
	if dequeued_value:
		dequeued_value.text = str(total_dequeued)
	if legacy_label:
		legacy_label.text = "Queue length: " + str(current_count)
		
	if progress_bar:
		var target_max = max(10.0, float(max(peak_count, current_count)))
		progress_bar.max_value = target_max
		progress_bar.value = float(current_count)
		
	if items_tree and empty_label:
		items_tree.clear()
		var root = items_tree.create_item()
		
		if items.is_empty():
			empty_label.visible = true
			items_tree.visible = false
		else:
			empty_label.visible = false
			items_tree.visible = true
			for item in items:
				if item is SimulationItem:
					var tree_item = items_tree.create_item(root)
					tree_item.set_text(0, "#" + str(item.sim_id))
					tree_item.set_text(1, str(item.properties.get("type", "standard")))
					tree_item.set_text(2, "%.2fs" % item.time_created)
