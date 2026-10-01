extends SimulationStateMachine
class_name Philosopher3

signal philosopher_state_changed

var eating_time_dist : TimeDistribution
var thinking_time_dist : TimeDistribution
var taking_time_dist : TimeDistribution
var time_out_time_dist : TimeDistribution

var first_chopstick: SimulationResourceManaged
var second_chopstick: SimulationResourceManaged

var portion : float 
var meal_size : float

var id : int = 0
var manager : SimulationManager # reference to simulation manager

var waiting_time = 0.0
var start_waiting_time = 0.0
var time_outs = 0

enum PHIL_STATE { THINKING, HUNGRY, TAKEFIRSTCHOPSTICK, ONECHOPSTICK, GETFOOD, EATING}

func _init():
	super()
	eating_time_dist = TimeDistribution.Constant.new(1.0)
	thinking_time_dist = TimeDistribution.Constant.new(1.0)
	taking_time_dist = TimeDistribution.Constant.new(1.0)
	time_out_time_dist = TimeDistribution.Constant.new(1.0)
	portion = 0
	init_state_machine()

func init_state_machine():
	add_state(PHIL_STATE.THINKING, Thinking.new(self))
	add_state(PHIL_STATE.HUNGRY, Hungry.new(self))
	add_state(PHIL_STATE.TAKEFIRSTCHOPSTICK, TakeFirstChopstick.new(self))
	add_state(PHIL_STATE.ONECHOPSTICK, HungyWithOneChopstick.new(self))
	add_state(PHIL_STATE.GETFOOD, GetFood.new(self))
	add_state(PHIL_STATE.EATING, Eating.new(self))

func restart_state_machine():
	meal_size = portion
	start_state(PHIL_STATE.THINKING)
	
func reset():
	time_outs = 0
	waiting_time = 0.0
	start_waiting_time = 0.0
	first_chopstick.release()
	second_chopstick.release()
	
# the states	
class Thinking extends SimulationStateMachine.State:
	func get_state_name() -> String:
		return "thinking"
	
	func enter():
		var m = get_machine()
		var delay = m.thinking_time_dist.get_interval() 
		m.manager.schedule_event(delay, m.process_event.bind("next"))
			
	func handle_event(_event_name):
		return PHIL_STATE.HUNGRY	
#
class Hungry extends SimulationStateMachine.State:
	func get_state_name() -> String:
		return "hungry"
		
	func enter():
		get_machine().start_waiting_time = get_machine().manager.sim_clock
		
	func handle_event(event_name):
		return PHIL_STATE.TAKEFIRSTCHOPSTICK	

class TakeFirstChopstick extends SimulationStateMachine.State:
	func get_state_name() -> String:
		return "take first chopstick"
		
	func enter():
		var m = get_machine()
		var delay = m.taking_time_dist.get_interval()
		m.manager.schedule_event(delay, m.process_event.bind("next"))
			
	func handle_event(_event_name):
		return PHIL_STATE.ONECHOPSTICK	


class HungyWithOneChopstick extends SimulationStateMachine.State:
	func get_state_name() -> String:
		return "one chopstick only"
		
	func handle_event(_event_name):
		return PHIL_STATE.GETFOOD	

class GetFood extends SimulationStateMachine.State:
	var waiting_id := 0 # to invalidate time outs

	func get_state_name() -> String:
		return "get food"
	
	func enter():
		waiting_id += 1
		var m = get_machine()
#		print("P", m.id, " ", m.manager.sim_clock, " get foot ", 	get_machine().meal_size)
		var delay = m.time_out_time_dist.get_interval()
		m.manager.schedule_event(delay, time_out.bind(waiting_id))

	func time_out(current_id : int):
		if (current_id == waiting_id):
			var m = get_machine()
#			print("P",m.id, " ", m.manager.sim_clock, " timeout")
			m.time_outs += 1
			m.waiting_time += (m.manager.sim_clock - m.start_waiting_time)
			m.meal_size += m.portion
			m.first_chopstick.release()
			m.second_chopstick.release()
			m.process_event("timeout")
	
	func handle_event(event_name):
		if (event_name == "timeout"): 
			return PHIL_STATE.THINKING
		else:
			waiting_id += 1
			return PHIL_STATE.EATING	


class Eating extends SimulationStateMachine.State:
	func get_state_name() -> String:
		return "eating"

	func enter():
		var m = get_machine()
#		print("P", m.id, " ", m.manager.sim_clock, " eating")
		m.waiting_time += (m.manager.sim_clock - m.start_waiting_time)
		var delay = m.eating_time_dist.get_interval() 
		m.manager.schedule_event(delay, m.process_event.bind("next"))

	func exit():
		get_machine().meal_size = get_machine().portion
		get_machine().first_chopstick.release()
		get_machine().second_chopstick.release()
		
	func handle_event(_event_name):
		return PHIL_STATE.THINKING	

# called from c condition for choppsticks
func on_resource_acquired(chopstick: SimulationResourceManaged):
	chopstick.acquire(self)
	process_event(null)

# called from c condition for chopsticks
func can_acquire(chopstick: SimulationResourceManaged) -> bool:
	if current_state_id == PHIL_STATE.HUNGRY: 
		var res = chopstick == first_chopstick and chopstick.is_available(self)
		return res
	elif current_state_id == PHIL_STATE.ONECHOPSTICK: 
		var res = chopstick == second_chopstick and chopstick.is_available(self)
		return res
	return false

# called from c condition for food bowl
func can_get(container: SimulationContainer) -> bool:
	if current_state_id == PHIL_STATE.GETFOOD:
		return container.has_enough(meal_size, self)
	return false
	
func on_container_got(container: SimulationContainer):
	container.get_amount(meal_size, self)
	process_event("food")
	
