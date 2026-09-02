extends Control

var value := Vector2.ZERO
var finger := -1
var center := Vector2.ZERO
var radius := 92.0
var knob_radius := 38.0
var active := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(true)
	set_process(true)

func _process(_delta: float) -> void:
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x < get_viewport_rect().size.x * 0.45 and event.position.y > get_viewport_rect().size.y * 0.42 and finger < 0:
			finger = event.index
			center = event.position
			active = true
			value = Vector2.ZERO
			queue_redraw()
		elif not event.pressed and event.index == finger:
			finger = -1
			active = false
			value = Vector2.ZERO
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == finger:
		value = ((event.position - center) / radius).limit_length(1.0)
		queue_redraw()

func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	var base := center if active else Vector2(132.0, viewport_size.y - 132.0)
	var outer := Color(0.05, 0.07, 0.09, 0.52)
	var rim := Color(0.78, 0.83, 0.86, 0.42)
	var knob := Color(0.72, 0.78, 0.82, 0.68)
	draw_circle(base, radius, outer)
	draw_arc(base, radius, 0.0, TAU, 64, rim, 3.0, true)
	draw_circle(base + value * (radius - knob_radius * 0.45), knob_radius, knob)
	draw_arc(base + value * (radius - knob_radius * 0.45), knob_radius, 0.0, TAU, 48, Color(0.95, 0.97, 1.0, 0.5), 2.0, true)
