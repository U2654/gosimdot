extends Window

@onready var spin_box: SpinBox = $MarginContainer/VBoxContainer/ConfigCard/HBoxContainer/OutputNumberSpinBox
@onready var port0_badge: Label = $MarginContainer/VBoxContainer/PortsCard/VBoxContainer/PortList/Port0Badge
@onready var port1_badge: Label = $MarginContainer/VBoxContainer/PortsCard/VBoxContainer/PortList/Port1Badge
@onready var port2_badge: Label = $MarginContainer/VBoxContainer/PortsCard/VBoxContainer/PortList/Port2Badge
@onready var port3_badge: Label = $MarginContainer/VBoxContainer/PortsCard/VBoxContainer/PortList/Port3Badge

func _ready() -> void:
	if spin_box:
		_update_port_indicators(int(spin_box.value))

func _on_output_number_spin_box_value_changed(value: float) -> void:
	var count := int(value)
	var parent_node = get_parent()
	if parent_node:
		var p2 = parent_node.get_node_or_null("OutPort2Label")
		var p3 = parent_node.get_node_or_null("OutPort3Label")
		if count == 3:
			if p2: p2.visible = true
			if p3: p3.visible = false
		elif count == 4:
			if p2: p2.visible = true
			if p3: p3.visible = true
		else:
			if p2: p2.visible = false
			if p3: p3.visible = false
		parent_node.size = Vector2.ZERO # force resize
		
	_update_port_indicators(count)

func _update_port_indicators(count: int) -> void:
	if port2_badge:
		port2_badge.text = "[ Enabled ]" if count >= 3 else "[ Disabled ]"
		port2_badge.modulate = Color(0.1, 0.6, 0.2) if count >= 3 else Color(0.5, 0.5, 0.5)
	if port3_badge:
		port3_badge.text = "[ Enabled ]" if count >= 4 else "[ Disabled ]"
		port3_badge.modulate = Color(0.1, 0.6, 0.2) if count >= 4 else Color(0.5, 0.5, 0.5)
