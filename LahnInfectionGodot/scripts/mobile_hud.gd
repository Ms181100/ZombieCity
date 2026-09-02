extends CanvasLayer

signal fire_pressed
signal reload_pressed
signal dodge_pressed
signal interact_pressed
signal pause_pressed

var health_label: Label
var ammo_label: Label
var objective_label: Label
var damage_overlay: ColorRect
var build_label: Label

func _ready() -> void:
	_build()

func _build() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var vignette := ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0.0, 0.0, 0.0, 0.08)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vignette)

	var status := HBoxContainer.new()
	status.position = Vector2(28, 24)
	status.add_theme_constant_override("separation", 14)
	root.add_child(status)
	health_label = _chip("❤ 100")
	ammo_label = _chip("12 / 48")
	status.add_child(health_label)
	status.add_child(ammo_label)

	var objective_panel := PanelContainer.new()
	objective_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	objective_panel.offset_left = 260
	objective_panel.offset_right = -260
	objective_panel.offset_top = 18
	objective_panel.offset_bottom = 78
	objective_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var objective_style := StyleBoxFlat.new()
	objective_style.bg_color = Color(0.018, 0.025, 0.032, 0.9)
	objective_style.border_width_bottom = 2
	objective_style.border_color = Color(0.72, 0.14, 0.09, 0.8)
	objective_style.corner_radius_bottom_left = 10
	objective_style.corner_radius_bottom_right = 10
	objective_panel.add_theme_stylebox_override("panel", objective_style)
	root.add_child(objective_panel)
	objective_label = Label.new()
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.add_theme_font_size_override("font_size", 18)
	objective_panel.add_child(objective_label)

	build_label = Label.new()
	build_label.text = "LAHN-INFECTION  •  ALPHA 0.3  •  BUILD 21"
	build_label.position = Vector2(28, 62)
	build_label.add_theme_font_size_override("font_size", 12)
	build_label.add_theme_color_override("font_color", Color(0.7,0.74,0.78,0.8))
	root.add_child(build_label)

	var pause := _action_button("Ⅱ", Vector2(-76, 20), Vector2(56, 56))
	pause.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause.pressed.connect(func(): pause_pressed.emit())
	root.add_child(pause)
	var fire := _action_button("FEUER", Vector2(-164, -166), Vector2(132, 132)); fire.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT); fire.pressed.connect(func(): fire_pressed.emit()); root.add_child(fire)
	var reload := _action_button("LADEN", Vector2(-302, -110), Vector2(104, 74)); reload.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT); reload.pressed.connect(func(): reload_pressed.emit()); root.add_child(reload)
	var dodge := _action_button("AUSWEICHEN", Vector2(-302, -202), Vector2(118, 70)); dodge.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT); dodge.pressed.connect(func(): dodge_pressed.emit()); root.add_child(dodge)
	var interact := _action_button("BENUTZEN", Vector2(-430, -124), Vector2(110, 74)); interact.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT); interact.pressed.connect(func(): interact_pressed.emit()); root.add_child(interact)

	var crosshair := Label.new(); crosshair.text = "＋"; crosshair.set_anchors_preset(Control.PRESET_CENTER); crosshair.position = Vector2(-10, -22); crosshair.add_theme_font_size_override("font_size", 28); crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(crosshair)
	damage_overlay = ColorRect.new(); damage_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); damage_overlay.color = Color(0.55, 0.0, 0.0, 0.0); damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(damage_overlay)

func set_status(health: int, ammo: int, reserve: int) -> void:
	if health_label: health_label.text = "❤ %d" % health
	if ammo_label: ammo_label.text = "▣ %d / %d" % [ammo, reserve]

func set_objective(text: String) -> void:
	if objective_label: objective_label.text = text

func flash_damage() -> void:
	if not damage_overlay: return
	damage_overlay.color = Color(0.55, 0.0, 0.0, 0.3)
	create_tween().tween_property(damage_overlay, "color", Color(0.55, 0.0, 0.0, 0.0), 0.34)

func _chip(text: String) -> Label:
	var label := Label.new(); label.text = text; label.add_theme_font_size_override("font_size", 20); label.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0)); return label

func _action_button(text: String, pos: Vector2, button_size: Vector2) -> Button:
	var button := Button.new(); button.text = text; button.position = pos; button.size = button_size; button.focus_mode = Control.FOCUS_NONE; button.add_theme_font_size_override("font_size", 15)
	var normal := StyleBoxFlat.new(); normal.bg_color = Color(0.025, 0.03, 0.036, 0.78); normal.border_width_left = 2; normal.border_width_top = 2; normal.border_width_right = 2; normal.border_width_bottom = 2; normal.border_color = Color(0.75, 0.8, 0.84, 0.3); normal.corner_radius_top_left = 20; normal.corner_radius_top_right = 20; normal.corner_radius_bottom_left = 20; normal.corner_radius_bottom_right = 20
	var pressed := normal.duplicate() as StyleBoxFlat; pressed.bg_color = Color(0.58, 0.07, 0.045, 0.94); pressed.border_color = Color(1.0,0.35,0.18,0.9)
	button.add_theme_stylebox_override("normal", normal); button.add_theme_stylebox_override("pressed", pressed); return button
