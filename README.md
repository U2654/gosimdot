# GoSimDot: Discrete-Event Simulation for the Godot Engine

**GoSimDot** is an open-source discrete-event simulation (DES) framework developed natively for the Godot Engine (Godot 4.x). It implements the classical **Three-Phase (ABC) simulation worldview**, combining high-speed headless execution for Monte Carlo experimentation, decoupled 2D/3D visual interactive simulation, and a prototype graph-based visual workflow editor.

---

## Key Features

- **Three-Phase Simulation Core (ABC):**
  - **Phase A (Clock Advance):** Jumps the simulation clock directly to the next scheduled event in the Future Event Set.
  - **Phase B (Bound Events):** Sequentially dequeues and executes deterministic, time-scheduled events (e.g. arrivals, service completions).
  - **Phase C (Conditional Activities):** Evaluates cooperative activities that depend on multiple system states (e.g. idle servers + waiting entities) using an efficient signal-based observer pattern rather than exhaustive polling.
- **Decoupled Architecture:** Simulation logic is completely independent of graphical nodes. The same simulation model can execute headlessly from a terminal, run within the Godot editor, or connect to custom 2D/3D visualizations via Godot signals.
- **Flexible Operational Modes:**
  1. **Headless GDScript Mode:** Fast command-line execution for batch replications and parameter sweeps.
  2. **Custom Visual Mode:** Attaching 2D/3D animations, state machines, and real-time dashboard plots (e.g. in [Dining Philosophers](examples/dining_philosophers/README.md) and [Processing Stages](examples/processing_stages/README.md)).
  3. **Flow-Based UI Mode:** Interactive drag-and-drop network construction on a `GraphEdit` canvas (proof-of-concept prototype; see [App README](app/README.md)).

---

## Core Example: The Booking Clerk Model

The classic **Booking Clerk** problem (from M. Pidd, *Computer Simulation in Management Science*) demonstrates the core mechanics of GoSimDot: two competing customer streams (**Personal** visitors and **Phone** calls) share a pool of clerks (`SimulationResource`), with personal callers given priority over telephone calls.

### 1. Defining the Conditional Activity (`ClerkTaskCondition`)

Conditional logic is encapsulated in a class derived from `SimulationCCondition`. By calling `watch()`, the condition registers interest in state mutations of the resource and queue without polling:

```gdscript
# clerk_c_condition.gd
class_name ClerkTaskCondition
extends SimulationCCondition

var manager: SimulationManager
var clerk: SimulationResource
var queue: SimulationQueue
var task_name: String

var service_dist: TimeDistribution
var arrival_dist: TimeDistribution

var arrivals: int = 0
var departures: int = 0

func _init(m: SimulationManager, c: SimulationResource, q: SimulationQueue, prio: int, t_name: String, 
	s_dist: TimeDistribution, a_dist: TimeDistribution) -> void:
	super()
	priority = prio
	manager = m
	clerk = c
	queue = q
	task_name = t_name
	service_dist = s_dist
	arrival_dist = a_dist
	
	# Connect signals: whenever clerk or queue changes state,
	# this condition is flagged for evaluation in Phase C.
	watch(clerk)
	watch(queue)

func is_true() -> bool:
	# Activity starts only if a clerk is available AND someone is waiting in the queue
	return clerk.is_available() and queue.get_count() > 0

func execute() -> void:
	# 1. Acquire the resource (decrements available capacity, emits state_changed)
	clerk.acquire()
	
	# 2. Dequeue the waiting entity
	var _item = queue.pop()
	
	# 3. Schedule the B-Phase event for service completion
	var service_duration = service_dist.get_interval()
	manager.schedule_event(service_duration, schedule_departure)

func schedule_departure() -> void:
	departures += 1
	# B-Phase: release the clerk, triggering a state_changed signal to restart Phase C
	clerk.release()

func schedule_arrival() -> void:
	arrivals += 1
	queue.push()
	# Schedule the next arrival B-event
	var arrival_interval = arrival_dist.get_interval()
	manager.schedule_event(arrival_interval, schedule_arrival)

func print_stats() -> void:
	print("%s | Queue length: %d, Arrivals: %d, Departures: %d" % [
		task_name, queue.get_count(), arrivals, departures
	])
```

### 2. Setting Up and Running the Simulation (`clerk_example.gd`)

```gdscript
# clerk_example.gd
extends Node

func _ready() -> void:
	# 1. Instantiate the SimulationManager
	var sim = SimulationManager.new()
	add_child(sim)

	# 2. Create queues and shared resource
	var personal_queue = SimulationQueue.new()
	var phone_queue = SimulationQueue.new()
	var clerks = SimulationResource.new()
	clerks.capacity = 2  # 2 booking clerks available

	# 3. Define arrival and service distributions
	var personal_arrival = TimeDistribution.Constant.new(12)
	var personal_service = TimeDistribution.Constant.new(15)
	var phone_arrival = TimeDistribution.Constant.new(10)
	var phone_service = TimeDistribution.Constant.new(15)

	# 4. Instantiate and register C-conditions (higher priority number = higher priority)
	var c_personal = ClerkTaskCondition.new(sim, clerks, personal_queue, 2, "Personal", personal_service, personal_arrival)
	var c_phone = ClerkTaskCondition.new(sim, clerks, phone_queue, 1, "Phone", phone_service, phone_arrival)
	sim.add_c_condition(c_personal)
	sim.add_c_condition(c_phone)

	# 5. Bootstrap initial arrivals
	sim.schedule_event(personal_arrival.get_interval(), c_personal.schedule_arrival)
	sim.schedule_event(phone_arrival.get_interval(), c_phone.schedule_arrival)

	# 6. Execute simulation until duration limit
	sim.run_duration = 100.0
	var finished_signal = sim.simulation_finished
	sim.simulate()
	await finished_signal

	# 7. Output final statistics
	c_personal.print_stats()
	c_phone.print_stats()
	get_tree().quit()
```

---

## Directory Structure

```text
gosimdot/
├── addons/
│   └── gosimdot/                       # Core plugin (see addons/gosimdot/README.md)
│       ├── plugin.cfg                  # Godot editor plugin metadata
│       ├── gosimdot.gd                 # Plugin registration
│       └── core/                       # Core simulation engine classes
├── app/                                # Flow-Based UI application (see app/README.md)
│   ├── graph_nodes/                    # GraphEdit node implementations
│   ├── gui/                            # Toolbars, menu bars, inspection dialogs
│   └── networks/                       # Serialized network graphs (JSON)
├── examples/                           # Reference simulation models
│   ├── dining_philosophers/            # Concurrency benchmark & animations (see README.md)
│   └── processing_stages/              # Three-stage production line (see README.md)
└── tests/                              # Verification test scenes and validation scripts
```

### [`addons/gosimdot/core/`](addons/gosimdot/README.md) (Simulation Kernel)
Contains the foundational object-oriented discrete-event simulation classes (see the [Core Addon README](addons/gosimdot/README.md) for full architecture and class details):
- **`simulation_manager.gd`**: The central simulation lifecycle controller. Tracks the discrete simulation clock (`sim_clock`), manages the Future Event Set (`event_list` for Phase A/B), and coordinates priority-based Phase C evaluation.
- **`simulation_entity.gd`**: Base class for observable simulation components. Emits `state_changed` signals upon state transitions.
- **`simulation_item.gd`**: Transient discrete simulation entity/token carrying `type`, `time_created`, and custom metadata `properties`.
- **`simulation_c_condition.gd`**: Base class for Phase C conditional logic. Provides `watch()`, `is_true()`, `execute()`, and priority management.
- **`simulation_resource.gd` & `simulation_resource_managed.gd`**: Manages finite server/token capacities (`acquire()`, `release()`, `is_available()`); the managed variant adds an internal priority request queue.
- **`simulation_queue.gd`**: FIFO buffer queue for waiting entities (`push()`, `pop()`, `get_count()`).
- **`simulation_container.gd` & `simulation_container_managed.gd`**: Continuous and discrete resource containers (e.g. food bowls, buffers) with fill capacities and threshold signals; the managed variant enforces queued replenishment/depletion claims.
- **`simulation_state_machine.gd`**: State machine abstraction for entities cycling through discrete operational states.
- **`time_distributions.gd`**: Built-in statistical distributions (Constant, Exponential, Normal, Uniform, Triangular, Empirical) providing `.get_interval()`.
- **`decider.gd`**: Probabilistic and conditional branching utility (`Decider`, `ProbablisticDecider`).

### [`app/`](app/README.md) (Flow-Based UI Mode)
Contains the proof-of-concept node-based workflow editor (see the [App README](app/README.md)):
- **`graph_main.tscn` / `graph_main.gd`**: Main UI application built with Godot's `GraphEdit`.
- **`graph_nodes/`**: Custom node implementations inheriting from `GraphNode` (`SimGraphNode`), representing `Source`, `Queue`, `Delay`, `Route`, `Decide`, `Resource`, and `Sink`. Supports drag-and-drop placement, color-coded port validation, and parameter configuration dialogs.
- **`gui/`**: Modal inspection dialogs and runtime control toolbars (step, run duration, speed controls).
- **`networks/`**: Pre-configured and saved simulation graph networks in JSON format (`three_processing_stages.json`, `demo.json`, `resource.json`, `router_2way.json`, `router_3way.json`, `parallel_servers.json`, `typed_service_delay.json`). Open and save dialogs in `graph_main` default directly to this directory.

### `examples/` (Reference Models & Demonstrations)
Reference implementations demonstrating various discrete-event systems and operational modes:
- **`booking_clerk/`**: Priority-based multi-queue booking clerk problem (M. Pidd).
- **`customer_queue/`**: Classic $M/M/c$ multi-server queue benchmark ($M/M/3$) evaluated against Python frameworks (SimPy, Ciw).
- **`customer_counter/`**: Customer lifecycle with sleep/wake states and item disposal (Zinoviev).
- **[`dining_philosophers/`](examples/dining_philosophers/README.md)**: Multi-entity concurrency benchmark (see [Dining Philosophers README](examples/dining_philosophers/README.md)) featuring:
  - `animation/`: Decoupled 2D circular interactive visualization with real-time state displays and food bowl depletion.
  - `plotting/`: Automated parameter sweep across $N$ philosophers with dynamic 2D runtime plot canvas.
  - `headless.gd`: High-speed batch evaluation script.
- **[`processing_stages/`](examples/processing_stages/README.md)**: Three-stage production logistics line with sequence-dependent setup times (Lang et al.) (see [Three Processing Stages README](examples/processing_stages/README.md)).
- **`queues_network/`**: Tandem queueing network with routing decisions and probabilistic splits.

### `tests/` (Verification & Unit Testing)
Test scenes and test scripts for automated validation:
- **`simulation_state_machine_example.tscn` / `.gd`**: Verification of state machine transitions and observer signals.
- **`time_distribution_control.tscn` / `.gd`**: Interactive visual inspector for validating distribution sampling and histograms.

---

## Getting Started

### Running in the Godot Editor
1. Open the project in **Godot 4.x**.
2. Run any example scene directly (e.g., `examples/booking_clerk/clerk_example.tscn`, [Dining Philosophers](examples/dining_philosophers/README.md) at `examples/dining_philosophers/animation/dining_philosophers_animation3.tscn`, or [Processing Stages](examples/processing_stages/README.md) at `examples/processing_stages/three_processing_stages_vis.tscn`) by pressing `F6`.
3. To test the node-based workflow editor, open and run `app/graph_main.tscn` (see [App README](app/README.md)).

### Running Headlessly (Command Line)
To execute simulations without GUI rendering for batch experiments and benchmarks:

```bash
# Run the booking clerk example
godot --headless -s examples/booking_clerk/clerk_example.gd

# Run the M/M/3 queue benchmark
godot --headless -s examples/customer_queue/customer_queue.gd
```

---

## License

GoSimDot is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

*Note: This documentation was generated with AI assistance (Gemini) and reviewed by the maintainer.*