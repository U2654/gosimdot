class_name SimulationResourceManaged
extends SimulationResource

var _queue: Array = [] #stores: { "entity": Object, "priority": int }

func is_free() -> bool:
	return _queue.is_empty()

func is_available(entity = null, priority: int = 0) -> bool:
	# if there is space in the queue..
	if used < capacity:
		# check if anyone is waiting in line ahead of us
		if _queue.is_empty() or (_queue[0].entity != null and _queue[0].entity.get_ref() == entity):
			return true
	
	# if the resource cannot be used, join the queue (if not already there)
	if entity != null and (res_owner == null or entity != res_owner.get_ref()):
		_register_request(entity, priority)
	return false

func acquire(entity = null):
	if used < capacity:
		# remove from queue as the resource was taken
		_queue = _queue.filter(func(item): return item.entity != null and item.entity.get_ref() != entity)
		res_owner = weakref(entity) if entity != null else null
		used += 1
		return true
	return false

func reset():
	super.reset()
	_queue.clear()

func release():
	super.release()

func _register_request(entity, priority):
	for item in _queue:
		if item.entity != null and item.entity.get_ref() == entity: 
			return 
	_queue.append({"entity": weakref(entity) if entity != null else null, "priority": priority})
	# to consider priorities
	_queue.sort_custom(func(a, b): return a.priority > b.priority)
