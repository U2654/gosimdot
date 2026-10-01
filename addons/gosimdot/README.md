# GoSimDot

**GoSimDot** is a discrete-event simulation (DES) framework for the Godot Engine (Godot 4.x). It implements classic 3-phase simulation execution, state machines, queues, shared resources, containers, dynamic entities, and parametric statistical distributions.

---

## Features & Core Architecture (`addons/gosimdot/core/`)

The framework kernel is built on modular, object-oriented GDScript classes in `addons/gosimdot/core/`:

### 1. Simulation Engine & Lifecycle
* **`SimulationManager` (`simulation_manager.gd`)**:
  * Central engine managing the simulation clock (`sim_clock`), event scheduling, and the Future Event Set (`event_list`).
  * Coordinates the **Three-Phase (ABC)** execution loop:
    * **Phase A**: Clock advances directly to the next scheduled event time.
    * **Phase B**: Executes bound/deterministic time events due at current clock.
    * **Phase C**: Evaluates state-dependent conditional activities registered via `add_c_condition()`, scanning in priority order.
* **`SimulationEntity` (`simulation_entity.gd`)**:
  * Base class for all observable simulation components.
  * Assigns unique identification (`sim_id`) and emits `state_changed` to alert observer conditions without polling.
* **`SimulationItem` (`simulation_item.gd`)**:
  * Extends `SimulationEntity` to represent transient discrete entities/tokens moving through queues, delays, and routers.
  * Tracks creation timestamp (`time_created`), entity category (`type`), and custom metadata (`properties` dictionary).
* **`SimulationCCondition` (`simulation_c_condition.gd`)**:
  * Base class for Phase C cooperative activities.
  * Provides `watch(entity)` to subscribe to entity state changes, `is_true()` condition checks, `execute()` callback, and configurable execution `priority`.

### 2. Queues, Containers & Shared Resources
* **`SimulationQueue` (`simulation_queue.gd`)**:
  * FIFO entity buffer supporting `push()`, `pop()`, `get_count()`, and `is_empty()`.
  * Emits `state_changed` upon item additions and removals.
* **`SimulationResource` (`simulation_resource.gd`)**:
  * Models finite, unqueued capacity tokens (e.g., clerks, tools, workstations) with `acquire()`, `release()`, `is_available()`, and `capacity` limits.
* **`SimulationResourceManaged` (`simulation_resource_managed.gd`)**:
  * Extends `SimulationResource` with an internal priority wait queue (`_queue`).
  * Automatically registers waiting entities and allocates capacity tokens according to requester priority.
* **`SimulationContainer` (`simulation_container.gd`)**:
  * Models continuous or bulk discrete capacity pools (e.g., buffers, food bowls, fluid tanks).
  * Tracks current `level` vs `capacity` with `has_enough()`, `get_amount()`, and `put_amount()`.
* **`SimulationContainerManaged` (`simulation_container_managed.gd`)**:
  * Extends `SimulationContainer` with an internal request queue (`_queue`) to enforce orderly FIFO/priority claims when replenishing or depleting container levels.

### 3. State Machines & Decision Logic
* **`SimulationStateMachine` (`simulation_state_machine.gd`)**:
  * State machine abstraction extending `SimulationEntity` for modeling entity lifecycle phases.
  * Supports custom states (`State` inner class with `enter()`, `exit()`, `do()`, `handle_event()`), transitions, and event processing.
* **`Decider` & `ProbablisticDecider` (`decider.gd`)**:
  * Pluggable decision utility for branching and routing.
  * `ProbablisticDecider` selects outcomes based on weighted percentage distributions configured via `add_option(option, percentage)`.

### 4. Statistical Distributions
* **`TimeDistribution` (`time_distributions.gd`)**:
  * Parametric random variate generators providing `.get_interval()`:
    * `TimeDistribution.Constant`: Deterministic fixed intervals.
    * `TimeDistribution.Exponential`: Memoryless Poisson arrival/service processes (parameter $\lambda$).
    * `TimeDistribution.Uniform`: Bounded uniform sampling between $[min, max]$.
    * `TimeDistribution.Normal`: Gaussian distribution ($\mu, \sigma$) with non-negative clamping.
    * `TimeDistribution.Triangular`: Bounded asymmetric distribution (mode, min, max).
    * `TimeDistribution.Empirical`: Custom discrete CDF tables.

---

## Installation

1. Copy the `addons/gosimdot` folder into your Godot project's `addons/` directory.
2. In the Godot editor, open **Project → Project Settings → Plugins**.
3. Enable the **GoSimDot** plugin.
4. Add `SimulationManager` to your scene tree or instantiate it directly in GDScript:

```gdscript
var sim := SimulationManager.new()
add_child(sim)

# Schedule an event 5.0 seconds into simulated time
sim.schedule_event(5.0, func(): print("Event fired at: ", sim.sim_clock))
sim.run_duration = 100.0
sim.simulate()
```

---

## License

MIT License. See [LICENSE](LICENSE) for details.

