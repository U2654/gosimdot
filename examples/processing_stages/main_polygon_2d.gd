extends Polygon2D

var item_color_a: Color = Color(0.96, 0.58, 0.12)
var item_color_b: Color = Color(0.14, 0.68, 0.93)
var text_color: Color = Color.WHITE

var start_queue_pos := Vector2(-60, 10)

var _in_queue = null
var _in_proc = null 

const item_radius = 15
const item_x_offset: int = 34
const font_size: int = 13

func _get_q_count() -> int:
	if _in_queue is SimulationQueue:
		return _in_queue.get_count()
	elif _in_queue != null and _in_queue is Array:
		return _in_queue.size()
	return 0

func _get_q_items() -> Array:
	if _in_queue is SimulationQueue:
		return _in_queue._items
	elif _in_queue != null and _in_queue is Array:
		return _in_queue
	return []

func _draw():
	var font: Font = ThemeDB.fallback_font
	
	# Draw container background card
	var bg_rect = Rect2(-230, -150, 340, 300)
	draw_rect(bg_rect, Color(0.16, 0.20, 0.26, 0.95), true)
	draw_rect(bg_rect, Color(0.32, 0.42, 0.56, 1.0), false, 2.0)
	
	# Queue section outline and label
	var q_rect = Rect2(-220, -135, 215, 270)
	draw_rect(q_rect, Color(0.12, 0.15, 0.20, 0.8), true)
	draw_rect(q_rect, Color(0.25, 0.32, 0.42, 0.8), false, 1.0)
	var q_count = _get_q_count()
	draw_string(font, Vector2(-210, -115), "Shared Queue (" + str(q_count) + ")", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.65, 0.75, 0.85))

	# Draw items in queue (up to 4 visible in lane, +N if more)
	var items = _get_q_items()
	if items.size() > 0:
		var pos = start_queue_pos
		var max_shown = 4
		var count = 0
		for i in items:
			if count < max_shown:
				var col = item_color_a if i.properties["type"] == "A" else item_color_b
				draw_circle(pos, item_radius, col)
				draw_arc(pos, item_radius, 0, TAU, 24, Color.WHITE, 1.2)
				var text = str(i.sim_id)
				var t_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
				draw_string(font, pos + Vector2(-t_size.x/2.0, t_size.y/3.0), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)
				pos -= Vector2(item_x_offset, 0)
			count += 1
		if q_count > max_shown:
			var extra = "+" + str(q_count - max_shown)
			draw_string(font, pos + Vector2(-5, 4), extra, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(1, 0.85, 0.2))

	# 3 Parallel Server Bays
	var server_y_offsets = [-95, 0, 95]
	for idx in range(3):
		var y_mid = server_y_offsets[idx]
		var s_rect = Rect2(15, y_mid - 40, 80, 80)
		var is_busy = false
		var active_item = null
		if _in_proc != null and _in_proc.has(idx) and _in_proc[idx].size() > 0:
			is_busy = true
			active_item = _in_proc[idx][0]
			
		var s_border_col = Color(0.96, 0.58, 0.12, 1.0) if is_busy else Color(0.25, 0.7, 0.35, 0.8)
		var s_bg_col = Color(0.22, 0.18, 0.12, 0.9) if is_busy else Color(0.12, 0.15, 0.20, 0.8)
		draw_rect(s_rect, s_bg_col, true)
		draw_rect(s_rect, s_border_col, false, 2.0)
		
		draw_string(font, Vector2(25, y_mid - 25), "Server " + str(idx), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.65, 0.75, 0.85))
		var s_status = "BUSY" if is_busy else "IDLE"
		var s_status_col = Color(0.96, 0.65, 0.2) if is_busy else Color(0.4, 0.85, 0.5)
		draw_string(font, Vector2(25, y_mid + 32), s_status, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, s_status_col)
		
		if active_item:
			var pos = Vector2(55, y_mid + 2)
			var col = item_color_a if active_item.properties["type"] == "A" else item_color_b
			draw_circle(pos, item_radius + 2, col)
			draw_arc(pos, item_radius + 2, 0, TAU, 24, Color.WHITE, 1.5)
			var text = str(active_item.sim_id)
			var t_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
			draw_string(font, pos + Vector2(-t_size.x/2.0, t_size.y/3.0), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)

func set_data(in_queue, in_proc):
	_in_queue = in_queue
	_in_proc = in_proc
