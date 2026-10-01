extends Polygon2D

var item_color_a: Color = Color(0.96, 0.58, 0.12)
var item_color_b: Color = Color(0.14, 0.68, 0.93)
var text_color: Color = Color.WHITE

var start_queue_pos := Vector2(-45, -70)
var start_in_proc_pos := Vector2(55, 0)

const item_radius = 15
const item_x_offset: int = 34
const font_size: int = 13

var _in_queue = null
var _in_proc = null 

func _draw():
	var font: Font = ThemeDB.fallback_font

	# Draw container background card
	var bg_rect = Rect2(-200, -140, 310, 280)
	draw_rect(bg_rect, Color(0.16, 0.20, 0.26, 0.95), true)
	draw_rect(bg_rect, Color(0.32, 0.42, 0.56, 1.0), false, 2.0)

	# Queue A section
	var qa_rect = Rect2(-190, -125, 175, 110)
	draw_rect(qa_rect, Color(0.20, 0.16, 0.12, 0.8), true)
	draw_rect(qa_rect, Color(0.96, 0.58, 0.12, 0.6), false, 1.5)
	var qa_count = _in_queue[0].get_count() if (_in_queue and _in_queue.size() > 0) else 0
	draw_string(font, Vector2(-180, -105), "Queue A (" + str(qa_count) + ")", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.96, 0.65, 0.2))

	# Queue B section
	var qb_rect = Rect2(-190, 15, 175, 110)
	draw_rect(qb_rect, Color(0.12, 0.18, 0.24, 0.8), true)
	draw_rect(qb_rect, Color(0.14, 0.68, 0.93, 0.6), false, 1.5)
	var qb_count = _in_queue[1].get_count() if (_in_queue and _in_queue.size() > 1) else 0
	draw_string(font, Vector2(-180, 35), "Queue B (" + str(qb_count) + ")", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.3, 0.75, 1.0))

	# Draw items in Queue A (top)
	if _in_queue and _in_queue.size() > 0:
		var pos = Vector2(-45, -70)
		var max_shown = 3
		var count = 0
		for i in _in_queue[0]._items:
			if count < max_shown:
				draw_circle(pos, item_radius, item_color_a)
				draw_arc(pos, item_radius, 0, TAU, 24, Color.WHITE, 1.2)
				var text = str(i.sim_id)
				var t_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
				draw_string(font, pos + Vector2(-t_size.x/2.0, t_size.y/3.0), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)
				pos -= Vector2(item_x_offset, 0)
			count += 1
		if _in_queue[0].get_count() > max_shown:
			var extra = "+" + str(_in_queue[0].get_count() - max_shown)
			draw_string(font, pos + Vector2(-5, 4), extra, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(1, 0.85, 0.2))

	# Draw items in Queue B (bottom)
	if _in_queue and _in_queue.size() > 1:
		var pos = Vector2(-45, 70)
		var max_shown = 3
		var count = 0
		for i in _in_queue[1]._items:
			if count < max_shown:
				draw_circle(pos, item_radius, item_color_b)
				draw_arc(pos, item_radius, 0, TAU, 24, Color.WHITE, 1.2)
				var text = str(i.sim_id)
				var t_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
				draw_string(font, pos + Vector2(-t_size.x/2.0, t_size.y/3.0), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)
				pos -= Vector2(item_x_offset, 0)
			count += 1
		if _in_queue[1].get_count() > max_shown:
			var extra = "+" + str(_in_queue[1].get_count() - max_shown)
			draw_string(font, pos + Vector2(-5, 4), extra, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(1, 0.85, 0.2))


	# Shared Operator Bay
	var op_rect = Rect2(15, -45, 80, 90)
	var is_busy = false
	var active_item = null
	if _in_proc != null:
		for k in _in_proc:
			if _in_proc[k].size() > 0:
				is_busy = true
				active_item = _in_proc[k][0]
				break

	var s_border_col = Color(0.96, 0.58, 0.12, 1.0) if is_busy else Color(0.25, 0.7, 0.35, 0.8)
	var s_bg_col = Color(0.22, 0.18, 0.12, 0.9) if is_busy else Color(0.12, 0.15, 0.20, 0.8)
	draw_rect(op_rect, s_bg_col, true)
	draw_rect(op_rect, s_border_col, false, 2.0)
	
	draw_string(font, Vector2(25, -28), "Operator", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.65, 0.75, 0.85))
	var s_status = "BUSY" if is_busy else "IDLE"
	var s_status_col = Color(0.96, 0.65, 0.2) if is_busy else Color(0.4, 0.85, 0.5)
	draw_string(font, Vector2(25, 36), s_status, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, s_status_col)

	if active_item:
		var pos = Vector2(55, 2)
		var col = item_color_a if active_item.properties["type"] == "A" else item_color_b
		draw_circle(pos, item_radius + 2, col)
		draw_arc(pos, item_radius + 2, 0, TAU, 24, Color.WHITE, 1.5)
		var text = str(active_item.sim_id)
		var t_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		draw_string(font, pos + Vector2(-t_size.x/2.0, t_size.y/3.0), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)

func set_data(in_queue, in_proc):
	_in_queue = in_queue
	_in_proc = in_proc
