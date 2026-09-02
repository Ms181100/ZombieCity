extends Control

var value := Vector2.ZERO
var finger := -1
var center := Vector2.ZERO
var radius := 78.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x < get_viewport_rect().size.x * 0.48 and finger < 0:
			finger = event.index
			center = event.position
			queue_redraw()
		elif not event.pressed and event.index == finger:
			finger = -1
			value = Vector2.ZERO
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == finger:
		value = ((event.position - center) / radius).limit_length(1.0)
		queue_redraw()

func _draw() -> void:
	var base := center if finger >= 0 else Vector2(115, size.y - 115)
	draw_circle(base, radius, Color(0.9, 0.9, 0.9, 0.16))
	draw_arc(base, radius, 0, TAU, 48, Color(0.9, 0.9, 0.9, 0.55), 3.0)
	draw_circle(base + value * radius, 31.0, Color(0.75, 0.82, 0.86, 0.55))
