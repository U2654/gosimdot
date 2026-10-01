extends Window

@onready var capacity_spin_box: SpinBox = $MarginContainer/VBoxContainer/ConfigCard/HBoxContainer/CapacitySpinBox
@onready var usage_value: Label = $MarginContainer/VBoxContainer/StatusCard/VBoxContainer/GridContainer/UsageValue
@onready var queue_value: Label = $MarginContainer/VBoxContainer/StatusCard/VBoxContainer/GridContainer/QueueValue
@onready var utilization_bar: ProgressBar = $MarginContainer/VBoxContainer/StatusCard/VBoxContainer/UtilizationBar

func _ready() -> void:
	update_status(0, int(capacity_spin_box.value) if capacity_spin_box else 1, 0)

func update_status(used: int, capacity: int, queued_requests: int) -> void:
	if usage_value:
		usage_value.text = "%d / %d in use" % [used, capacity]
	if queue_value:
		queue_value.text = "%d waiting" % queued_requests
	if utilization_bar:
		utilization_bar.max_value = max(1.0, float(capacity))
		utilization_bar.value = float(used)
		var pct = (float(used) / max(1.0, float(capacity))) * 100.0
		utilization_bar.tooltip_text = "Utilization: %.1f%%" % pct
