# ClerkTaskCondition.gd
class_name ClerkTaskCondition
extends SimulationCCondition

var manager: SimulationManager
var clerk: SimulationResource
var queue: SimulationQueue 
var task_name: String

var service_dist : TimeDistribution
var arrival_dist : TimeDistribution

var arrivals : int = 0
var departures : int = 0

func _init(m: SimulationManager, c: SimulationResource, q: SimulationQueue, prio: int, t_name: String, 
	s_dist: TimeDistribution, a_dist: TimeDistribution):
	super()
	priority = prio
	manager = m
	clerk = c
	queue = q
	task_name = t_name
	service_dist = s_dist
	arrival_dist = a_dist
	
	# connect signals: if the clerk becomes free OR the queue gets a new item, 
	# this condition requests to be evaluated by the manager.
	watch(clerk)
	watch(queue)

func is_true() -> bool:
	# the condition is met only if the clerk can take a job AND someone is waiting.
	# if the condition is true, execute() will be called
	print(task_name + " : queue size of " + str(queue.get_count()))
	return clerk.is_available() and queue.get_count() > 0

func execute():
	# 1. ACQUIRE the clerk (increments 'used' and emits state_changed)
	clerk.acquire()
	
	# 2. POP someone from the queue
	var item = queue.pop()
	
	# prepare scheduling of  event 
	var duration = service_dist.get_interval()

	print(task_name + " [%0.2f] START: %s. (Clerks busy: %d/%d)" % [manager.sim_clock, arrivals, clerk.used, clerk.capacity])

	# 3. SCHEDULE the B-Phase (the moment the work ends)
	manager.schedule_event(duration, schedule_departure)
	
func schedule_departure():
	departures += 1
	# this is the B-Phase logic:
	clerk.release() # frees clerk, triggers state_changed, starts next C-Phase
	print(task_name + " [%0.2f] FINISH: %s. (Clerks busy: %d/%d)" % [manager.sim_clock, departures, clerk.used, clerk.capacity])
	
func schedule_arrival():
	arrivals += 1
	queue.push()
	print(task_name + " [%0.2f] arrival: %s" % [manager.sim_clock, arrivals])
	var arrival_time = arrival_dist.get_interval()
	manager.schedule_event(arrival_time, schedule_arrival, 1)

func print_stats():
	print(task_name + " Queue length: " + str(queue.get_count()) + ", arrivals: " + str(arrivals) + " departures: " + str(departures))
	
