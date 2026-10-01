extends Node

enum STATE {ONE = 1, TWO = 2, THREE = 3}

var state_machine := SimulationStateMachine.new()

func _ready():
	var one_state := OneState.new(state_machine)
	var two_state := TwoState.new(state_machine)
	var three_state := ThreeState.new(state_machine)
	state_machine.add_state(STATE.ONE, one_state)
	state_machine.add_state(STATE.TWO, two_state)
	state_machine.add_state(STATE.THREE, three_state)
	
	state_machine.start_state(STATE.ONE)

func process_event(event: String):
	state_machine.process_event(event)

class OneState extends SimulationStateMachine.State:
	func enter():
		print("enter one")
	
	func exit():
		print("exit one")
		
	func do(delta):
		print("do one")
		return -1

	func handle_event(event_name):
		if (event_name == "a"):
			print("one: event a")
			return STATE.TWO
		elif (event_name == "b"):
			print("one: event b")
			return STATE.THREE
		return -1
		
class TwoState extends SimulationStateMachine.State:
	func enter():
		print("enter two")
	
	func exit():
		print("exit two")
		
	func do(delta):
		print("do two")
		return -1
		
	func handle_event(event_name):
		if (event_name == "a"):
			return STATE.THREE
		return -1

class ThreeState extends SimulationStateMachine.State:
	func enter():
		print("enter three")
	
	func exit():
		print("exit three")
		
	func do(delta):
		print("do three")
		return -1
		
	func handle_event(event_name):
		if (event_name == "a"):
			return STATE.ONE
		return -1
