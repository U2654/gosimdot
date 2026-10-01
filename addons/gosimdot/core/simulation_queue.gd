class_name SimulationQueue
extends SimulationEntity

# queue for general items
var _items: Array = []

# add to queue
func push(item = null):
	_items.append(item)
	# notify the change to the system
	state_changed.emit()

# take from queue
func pop():
	if _items.is_empty():
		return null
		
	var item = _items.pop_front()
	# notify the change to the system
	state_changed.emit()
	return item

func get_count() -> int:
	return _items.size()

func is_empty() -> bool:
	return _items.is_empty()
	
func reset():
	_items.clear()
	
