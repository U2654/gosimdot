# this example corresponds to the reference scenario of 
# Lang et al. (2021), Open-source discrete-event simulation software..., Proc. Comp. Science
extends Node

@export var max_simulation_time : float = 100.0

var sim := SimulationManager.new()

var pre_processing := PreProcessingStage.new()
var main_processing := MainProcessingStage.new()
var post_processing :=  PostProcessingStage.new()

var td_arrival := TimeDistribution.Exponential.new(0.1)
var td_pre_processing := TimeDistribution.Normal.new(6, 2.5)
var td_main_processing_no_setup := TimeDistribution.Constant.new(8)
var td_main_processing_setup := TimeDistribution.Uniform.new(8, 12.5)
var td_post_processing := TimeDistribution.Triangular.new(6, 16, 10)

var product_type_creation_decider : Decider

func _ready() -> void:
	add_child(sim)
	
	product_type_creation_decider = Decider.ProbablisticDecider.new()
	product_type_creation_decider.add_option("A", 0.5)
	product_type_creation_decider.add_option("B", 0.5)

	pre_processing.name = "Pre"
	pre_processing.sim = sim
	pre_processing.number_of_servers = 1
	pre_processing.td_server = td_pre_processing
	add_child(pre_processing)
	pre_processing.item_ready.connect(pre_processing_finished)

	main_processing.name = "Main"
	main_processing.sim = sim
	main_processing.number_of_servers = 3
	main_processing.td_server_no_setup = td_main_processing_no_setup
	main_processing.td_server_setup = td_main_processing_setup
	add_child(main_processing)
	main_processing.item_ready.connect(main_processing_finished)
 
	post_processing.name = "Post"
	post_processing.sim = sim
	post_processing.number_of_queues = 2
	post_processing.td_server = td_post_processing
	post_processing.options = {"A":0, "B":1}
	add_child(post_processing)
	post_processing.item_ready.connect(post_processing_finished)

	sim.run_duration = max_simulation_time
	sim.schedule_event(td_arrival.get_interval(), item_arrives)

func run():
	sim.simulate()

func step():
	sim.step()

func reset():
	sim.reset()
	pre_processing.reset()
	main_processing.reset()
	post_processing.reset()
	sim.schedule_event(td_arrival.get_interval(), item_arrives)
	

func set_duration(duration: float):
	sim.run_duration = duration	


# input to preprocessing
func item_arrives():
	var item = SimulationItem.new(sim.sim_clock)
	item.properties["type"] = product_type_creation_decider.get_decision()
#	print(sim.sim_clock, ": ", item.sim_id, " of type ", item.properties["type"], " -> pre")
	pre_processing.item_arrival(item)
	# schedule next arrival 
	sim.schedule_event(td_arrival.get_interval(), item_arrives)
		
func pre_processing_finished(item: SimulationItem):
#	print(sim.sim_clock, " ", item.sim_id, " of type ", item.properties["type"], " pre -> main")
	main_processing.item_arrival(item)
	
func main_processing_finished(item: SimulationItem):
	post_processing.item_arrival(item)
		
func post_processing_finished(item: SimulationItem):
	var processing_time = item.time_created - sim.sim_clock
	
