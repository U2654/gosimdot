# Simulation Graph Networks

This directory contains serialized node-based network models in JSON format, designed to be opened, edited, and simulated in the Flow-Based UI editor ([`app/graph_main.tscn`](file:///Users/matthias/git-repos/gosimdot/app/graph_main.tscn)).

## Available Networks

| Network File | Pattern / Purpose | Topology & Key Features |
|---|---|---|
| **`three_processing_stages.json`** | Multi-Stage Benchmark Line (Lang et al., 2021) | Full 3-stage model: Arrivals $\rightarrow$ Pre-processing $\rightarrow$ 3 parallel Main servers with sequence-dependent setup $\rightarrow$ Post-processing with dedicated Type A/B queues and 1 shared operator. |
| **`demo.json`** | Two-Stage Tandem Queue Line | Linear sequential line: `Source` $\rightarrow$ `Queue 1` $\rightarrow$ `Delay 1` $\rightarrow$ `Queue 2` $\rightarrow$ `Delay 2` $\rightarrow$ `Sink`. |
| **`resource.json`** | Dual-Stream Shared Resource Contention | Two parallel item streams (`Source 1` $\rightarrow$ `Queue 1` $\rightarrow$ `Delay 1` and `Source 2` $\rightarrow$ `Queue 2` $\rightarrow$ `Delay 2`) contending for a single shared `ResourceNode`. |
| **`router_2way.json`** | Processing Stage with 2-Way Typed Routing | `Source` (tagged by `SourceDecide`) $\rightarrow$ `Queue` $\rightarrow$ `Delay` $\rightarrow$ `RouteNode` (split by `RouteDecide`) $\rightarrow$ 2 dedicated Sinks. |
| **`router_3way.json`** | 3-Way Routing Classifier | `Source` (classified into Types A, B, C via `SourceDecide`) $\rightarrow$ `Queue` $\rightarrow$ `RouteNode` (split 3 ways by `RouteDecide`) $\rightarrow$ 3 dedicated Sinks. |
| **`parallel_servers.json`** | Dual Parallel Server Bank | Single queue distributing jobs to two parallel delay stations (`RouteNode` allocating to the first available server) $\rightarrow$ Sinks. |
| **`typed_service_delay.json`** | Type-Dependent Service Time Queue | Single queue with typed service: `SourceDecide` (A/B tags) $\rightarrow$ `Queue` $\rightarrow$ `Delay` with `DelayDecide` applying different service distributions depending on item type $\rightarrow$ `Sink`. |

## How to Load and Save

1. Open and run `app/graph_main.tscn` in Godot (`F6`).
2. Use the menu bar: **File $\rightarrow$ Open**.
3. Select any `.json` file from `res://app/networks/` to load and simulate the graph.
4. Step through (`Step`), simulate continuously (`Run`), or edit and save back via **File $\rightarrow$ Save**.

---

*Note: This documentation was generated with AI assistance (Gemini) and reviewed by the maintainer.*
