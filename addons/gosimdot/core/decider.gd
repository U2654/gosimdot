class_name Decider
extends RefCounted

var options : Dictionary = {}

func reset():
	options.clear()

# to be overridden 
func get_decision():
	return null
	
class ProbablisticDecider extends Decider:
	
	func add_option(option, percentage: float):
		options[option] = percentage
	
	func get_decision() -> Variant:
		if options.is_empty():
			return null
		
		var cumulative := 0.0
		var r := randf()
		var last_option: Variant = null
		for o in options:
			last_option = o
			cumulative += options[o]
			if r < cumulative:
				return o
		return last_option

# Alias for standard spelling
class ProbabilisticDecider extends ProbablisticDecider:
	pass
	

#class DeterministicDecider extends Decider:
# ToDo
