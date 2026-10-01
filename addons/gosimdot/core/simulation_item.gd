class_name SimulationItem
extends SimulationEntity

var type: String = "none"
var properties: Dictionary = {}

var time_created : float = 0.0

func _init(t: float):
	super()
	self.time_created = t
