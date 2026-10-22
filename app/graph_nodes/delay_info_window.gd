extends Window

@onready var status_value: Label = $MarginContainer/VBoxContainer/PerformanceCard/VBoxContainer/GridContainer/StatusValue
@onready var util_value: Label = $MarginContainer/VBoxContainer/PerformanceCard/VBoxContainer/GridContainer/UtilValue
@onready var processed_value: Label = $MarginContainer/VBoxContainer/PerformanceCard/VBoxContainer/GridContainer/ProcessedValue
@onready var avg_service_value: Label = $MarginContainer/VBoxContainer/PerformanceCard/VBoxContainer/GridContainer/AvgServiceValue
@onready var util_progress_bar: ProgressBar = $MarginContainer/VBoxContainer/PerformanceCard/VBoxContainer/UtilProgressBar

func _resolve_nodes():
	if not status_value:
		status_value = find_child("StatusValue", true, false)
	if not util_value:
		util_value = find_child("UtilValue", true, false)
	if not processed_value:
		processed_value = find_child("ProcessedValue", true, false)
	if not avg_service_value:
		avg_service_value = find_child("AvgServiceValue", true, false)
	if not util_progress_bar:
		util_progress_bar = find_child("UtilProgressBar", true, false)

func update_stats(status_text: String, utilisation: float, processed_count: int, avg_service_time: float) -> void:
	_resolve_nodes()
	if status_value:
		status_value.text = status_text
	if util_value:
		util_value.text = "%.1f %%" % utilisation
	if processed_value:
		processed_value.text = "%d items" % processed_count
	if avg_service_value:
		avg_service_value.text = "%.2f s" % avg_service_time
	if util_progress_bar:
		util_progress_bar.value = clampf(utilisation, 0.0, 100.0)
