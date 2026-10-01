# Resource graph node
extends DecideGraphNode

func get_node_type_name() -> String:
	return "Resource Pool"

var resource := SimulationResourceManaged.new()

func _ready():
	super._ready()
	var sb = info_window.find_child("CapacitySpinBox", true, false)
	if sb:
		sb.value_changed.connect(change_capacity)
	_update_info_ui()

func _update_info_ui():
	if has_node("Label"):
		if resource.used == 0:
			$Label.text = "Pool: %d (Idle)" % resource.capacity
		else:
			$Label.text = "Used: %d / %d" % [resource.used, resource.capacity]
	if info_window and info_window.has_method("update_status"):
		var queue_count = resource._queue.size() if ("_queue" in resource) else 0
		info_window.update_status(resource.used, resource.capacity, queue_count)

func change_capacity(cap):
	resource.capacity = int(cap)
	_update_info_ui()

func set_callback(cb, ic):
	var c_condition := DeciderCCondition.new(self, ic, cb) 
	var sim := get_node("/root/Main/SimulationManager")
	sim.add_c_condition(c_condition)

func aquire(entity):
	#print(entity, " ACQUIRE")
	resource.acquire(entity)
	_update_info_ui()

func release(_entity):
	#print(_entity, " RELEASE")
	resource.release()
	_update_info_ui()

func reset():
	resource.reset()
	_update_info_ui()
		
# inner class for c-condition to have all in one file 
class DeciderCCondition extends SimulationCCondition:
	var _parent : Node
	var _callback : Callable
	var _input_check: SimulationEntity

	# watch server and queue for changes to check condition
	func _init(p: Node, ic, cb):
		_parent = p
		_input_check = ic
		_callback = cb
		watch(_parent.resource)
		watch(_input_check)

	# trigger execution if server is available and customer in the queue
	func is_true() -> bool:
		#print(_input_check, " CHECK ", _input_check.available)
		if _input_check.available:
			if _parent.resource.is_available(_input_check):
				#print(_input_check, " CHECK and RESOURCE availabe" )
				return true
		return false

	# execution calls customer_service
	func execute():
		_callback.call()
