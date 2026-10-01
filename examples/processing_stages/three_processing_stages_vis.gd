extends Node2D

var is_playing: bool = false
var step_interval: float = 0.2
var step_timer: float = 0.0

@onready var stages = $ThreeProcessingStages
@onready var sim_control = $SimControlBar
@onready var log_label = $LogPanel/VBoxContainer/LogRichTextLabel

func _ready() -> void:
	$PrePolygon2D.set_data(stages.pre_processing.item_queue, 
		stages.pre_processing.item_served)
	$MainPolygon2D.set_data(stages.main_processing.item_queue,
		stages.main_processing.item_served)
	$PostPolygon2D.set_data(stages.post_processing.item_queues, 
		stages.post_processing.item_served)

	stages.pre_processing.log_msg.connect(log_label.log_message)
	stages.main_processing.log_msg.connect(log_label.log_message)
	stages.post_processing.log_msg.connect(log_label.log_message)

	if sim_control.has_node("PlayButton"):
		var play_btn = sim_control.get_node("PlayButton")
		if not play_btn.pressed.is_connected(_on_play_button_pressed):
			play_btn.pressed.connect(_on_play_button_pressed)

	refresh_all()

func _process(delta: float) -> void:
	if is_playing:
		step_timer += delta
		if step_timer >= step_interval:
			step_timer = 0.0
			stages.step()
			refresh_all()
			
			# Check termination conditions: empty event list or reached run duration
			if stages.sim.event_list.is_empty() or stages.sim.sim_clock >= stages.sim.run_duration:
				is_playing = false
				_update_play_button()

func _on_play_button_pressed() -> void:
	is_playing = not is_playing
	if is_playing and stages.sim.sim_clock >= stages.sim.run_duration:
		# Auto-extend duration by 50 so play can continue smoothly
		stages.sim.run_duration = stages.sim.sim_clock + 50.0
		if sim_control.has_node("DurationLineEdit"):
			sim_control.get_node("DurationLineEdit").text = str(stages.sim.run_duration)
	step_timer = step_interval
	_update_play_button()

func _update_play_button() -> void:
	if sim_control.has_node("PlayButton"):
		var btn = sim_control.get_node("PlayButton")
		btn.text = "⏸ Pause" if is_playing else "▶ Play"

func _on_reset_button():
	is_playing = false
	_update_play_button()
	log_label.clear()
	stages.reset()
	refresh_all()

func _on_step_button():
	stages.step()
	refresh_all()

func _on_run_button():
	is_playing = false
	_update_play_button()
	stages.run()
	refresh_all()

func _on_duration_line_edit(new_text: String):
	var nb : float = new_text.to_float()
	stages.set_duration(nb)

func refresh_all():
	$PrePolygon2D.queue_redraw()
	$MainPolygon2D.queue_redraw()	
	$PostPolygon2D.queue_redraw()
	
	var clock_str = str(stages.sim.sim_clock).pad_decimals(2)
	sim_control.get_node("TimeLabel").text = "Clock: " + clock_str
	
	if has_node("StatusPanel"):
		var pre_q = stages.pre_processing.item_queue.get_count()
		var pre_busy = stages.pre_processing.item_served.size()
		
		var main_q = stages.main_processing.item_queue.get_count()
		var main_busy = 0
		for s in stages.main_processing.item_served:
			main_busy += stages.main_processing.item_served[s].size()
			
		var post_qa = stages.post_processing.item_queues[0].get_count() if stages.post_processing.item_queues.size() > 0 else 0
		var post_qb = stages.post_processing.item_queues[1].get_count() if stages.post_processing.item_queues.size() > 1 else 0
		var post_busy = 0
		for s in stages.post_processing.item_served:
			post_busy += stages.post_processing.item_served[s].size()
			
		var total_wip = pre_q + pre_busy + main_q + main_busy + post_qa + post_qb + post_busy
		
		$StatusPanel/VBoxContainer/ClockVal.text = "Sim Clock: " + clock_str + " / " + str(stages.sim.run_duration)
		$StatusPanel/VBoxContainer/WIPVal.text = "Work In Progress (WIP): " + str(total_wip) + " items"
		$StatusPanel/VBoxContainer/PreVal.text = "Stage 1 (Pre):  Queue: " + str(pre_q) + " | Server: " + ("BUSY" if pre_busy > 0 else "IDLE")
		$StatusPanel/VBoxContainer/MainVal.text = "Stage 2 (Main): Queue: " + str(main_q) + " | Servers: " + str(main_busy) + " / 3 Busy"
		$StatusPanel/VBoxContainer/PostVal.text = "Stage 3 (Post): Q_A: " + str(post_qa) + " | Q_B: " + str(post_qb) + " | Op: " + ("BUSY" if post_busy > 0 else "IDLE")
