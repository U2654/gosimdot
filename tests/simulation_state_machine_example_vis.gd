extends Control

func _ready():
	_on_statemachine_changed()
	$SimulationStateMachineExample.state_machine.state_changed.connect(_on_statemachine_changed)
	
func _on_statemachine_changed():
	var state = $SimulationStateMachineExample.state_machine.current_state_id
	match state:
		1: 
			highlight_state($OneLabel)
		2:
			highlight_state($TwoLabel)
		3:
			highlight_state($ThreeLabel)
		_:
			pass
						
func highlight_state(label : Label):
	# reset all
	$OneLabel.remove_theme_stylebox_override("normal")
	$TwoLabel.remove_theme_stylebox_override("normal")
	$ThreeLabel.remove_theme_stylebox_override("normal")
	# highlight one
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.8, 0.8, 0.0, 0.8) # Dark gray background
	# Apply it to the label
	label.add_theme_stylebox_override("normal", sb)
	
