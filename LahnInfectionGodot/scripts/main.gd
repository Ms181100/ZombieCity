extends Node3D

const Zombie = preload("res://scripts/zombie.gd")
const Joystick = preload("res://scripts/joystick.gd")

var player: CharacterBody3D
var camera: Camera3D
var camera_pivot: Node3D
var joystick: Control
var hud: Label
var objective_label: Label
var settings_panel: PanelContainer
var sound_player: AudioStreamPlayer
var sound_playback: AudioStreamGeneratorPlayback
var health := 100
var ammo := 12
var reserve := 48
var points := 0
var kills := 0
var mission_stage := 0
var yaw := 0.0
var pitch := -0.16
var look_finger := -1
var paused := false
var sound_enabled := true
var aim_assist := true
var sensitivity := 0.0045

var objectives := [
	"Verlasse den Keller und finde die B49.",
	"Sichere den Weg zur Apotheke (0/5).",
	"Durchsuche die Apotheke nach Medikamenten.",
	"Erreiche die Feuerwehrwache.",
	"Besiege den Wächter vor der Wache.",
	"Starte den Generator und sende das letzte Signal."
]

func _ready() -> void:
	get_viewport().set_embedding_subwindows(false)
	_build_environment()
	_build_player()
	_build_audio()
	_build_ui()
	_spawn_zombies()
	_update_hud()

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("07101b")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("52627a")
	environment.ambient_light_energy = 0.42
	environment.fog_enabled = true
	environment.fog_light_color = Color("253142")
	environment.fog_density = 0.012
	world.environment = environment
	add_child(world)
	var moon := DirectionalLight3D.new()
	moon.light_color = Color("91aad1")
	moon.light_energy = 1.1
	moon.rotation_degrees = Vector3(-50, -25, 0)
	moon.shadow_enabled = true
	add_child(moon)
	_block("B49", Vector3(0, -0.3, 45), Vector3(14, 0.5, 112), Color("17191d"))
	for marker in range(-5, 6):
		_block("Fahrbahnmarkierung", Vector3(0, 0.01, marker * 11 + 45), Vector3(0.16, 0.03, 5.0), Color("d2c995"))
	for side in [-1, 1]:
		_block("Gehweg", Vector3(side * 8.5, 0, 45), Vector3(3, 0.35, 112), Color("53565a"))
		for index in range(10):
			var height := 7.0 + float(index % 3) * 1.6
			var color := Color("49352b") if index % 2 == 0 else Color("555047")
			_block("Fachwerkhaus", Vector3(side * 12.2, height / 2.0, index * 12.0 - 10.0), Vector3(5.2, height, 10.5), color)
	_block("APOTHEKE", Vector3(-11.5, 2.8, 38), Vector3(5.5, 5.5, 11), Color("31563d"))
	_block("FEUERWEHR", Vector3(11.5, 3.2, 84), Vector3(6.5, 6.5, 14), Color("6c211c"))
	for car_z in [18.0, 31.0, 58.0, 72.0]:
		_block("Verlassenes Auto", Vector3(3.2 if int(car_z) % 2 == 0 else -3.2, 0.65, car_z), Vector3(2.2, 1.2, 4.2), Color("303943"))

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Überlebender"
	player.position = Vector3(0, 1.1, -7)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45; capsule.height = 1.8
	collision.shape = capsule
	player.add_child(collision)
	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.45; body_mesh.height = 1.8
	body.mesh = body_mesh
	body.material_override = _material(Color("284e72"), 0.8)
	player.add_child(body)
	add_child(player)
	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 1.4, 0)
	player.add_child(camera_pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0, 1.15, 4.5)
	camera.fov = 64
	camera_pivot.add_child(camera)

func _build_audio() -> void:
	sound_player = AudioStreamPlayer.new()
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = 0.25
	sound_player.stream = generator
	add_child(sound_player)
	sound_player.play()
	sound_playback = sound_player.get_stream_playback()

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	joystick = Joystick.new()
	joystick.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(joystick)
	hud = Label.new()
	hud.position = Vector2(18, 14)
	hud.add_theme_font_size_override("font_size", 23)
	canvas.add_child(hud)
	objective_label = Label.new()
	objective_label.position = Vector2(18, 48)
	objective_label.size = Vector2(850, 70)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.add_theme_font_size_override("font_size", 20)
	canvas.add_child(objective_label)
	var fire := _button("FEUER", Vector2(-145, -145), Vector2(122, 122), Color("9d2929"))
	fire.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	fire.pressed.connect(fire_weapon)
	canvas.add_child(fire)
	var reload := _button("LADEN", Vector2(-270, -105), Vector2(105, 82), Color("98761f"))
	reload.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	reload.pressed.connect(reload_weapon)
	canvas.add_child(reload)
	var options := _button("OPTIONEN", Vector2(-175, 18), Vector2(150, 58), Color("252b33"))
	options.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	options.pressed.connect(toggle_settings)
	canvas.add_child(options)
	_build_settings(canvas)
	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-8, -16)
	crosshair.add_theme_font_size_override("font_size", 28)
	canvas.add_child(crosshair)

func _build_settings(canvas: CanvasLayer) -> void:
	settings_panel = PanelContainer.new()
	settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	settings_panel.position = Vector2(-245, -210)
	settings_panel.size = Vector2(490, 420)
	settings_panel.visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	settings_panel.add_child(box)
	var title := Label.new(); title.text = "EINSTELLUNGEN"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 30); box.add_child(title)
	var sound_toggle := CheckButton.new(); sound_toggle.text = "Soundeffekte"; sound_toggle.button_pressed = true; sound_toggle.toggled.connect(func(on): sound_enabled = on); box.add_child(sound_toggle)
	var aim_toggle := CheckButton.new(); aim_toggle.text = "Zielhilfe"; aim_toggle.button_pressed = true; aim_toggle.toggled.connect(func(on): aim_assist = on); box.add_child(aim_toggle)
	var sensitivity_label := Label.new(); sensitivity_label.text = "Kamera-Empfindlichkeit"; box.add_child(sensitivity_label)
	var slider := HSlider.new(); slider.min_value = 0.002; slider.max_value = 0.009; slider.step = 0.0005; slider.value = sensitivity; slider.value_changed.connect(func(value): sensitivity = value); box.add_child(slider)
	var back := Button.new(); back.text = "ZURÜCK ZUM SPIEL"; back.custom_minimum_size.y = 64; back.pressed.connect(toggle_settings); box.add_child(back)
	canvas.add_child(settings_panel)

func _spawn_zombies() -> void:
	for index in range(15):
		var zombie := Zombie.new()
		var kind := Zombie.Kind.RENNER if index in [5, 10] else Zombie.Kind.WAECHTER if index == 14 else Zombie.Kind.SCHLURFER
		zombie.position = Vector3((-1 if index % 2 == 0 else 1) * (2.2 + index % 3), 1.0, 12.0 + index * 5.2)
		add_child(zombie)
		zombie.setup(kind, player, self)

func _physics_process(delta: float) -> void:
	if paused: return
	var keyboard := Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	).normalized()
	var input_vector: Vector2 = joystick.value if joystick.value.length() > 0.05 else keyboard
	var direction := (player.transform.basis * Vector3(input_vector.x, 0, input_vector.y)).normalized()
	player.velocity.x = direction.x * (5.8 if input_vector.length() > 0.92 else 3.4)
	player.velocity.z = direction.z * (5.8 if input_vector.length() > 0.92 else 3.4)
	player.velocity.y = -2.0 if player.is_on_floor() else player.velocity.y - 18.0 * delta
	player.move_and_slide()
	_update_mission_by_position()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x > get_viewport().get_visible_rect().size.x * 0.48 and look_finger < 0:
			look_finger = event.index
		elif not event.pressed and event.index == look_finger:
			look_finger = -1
	elif event is InputEventScreenDrag and event.index == look_finger and not paused:
		yaw -= event.relative.x * sensitivity
		pitch = clamp(pitch - event.relative.y * sensitivity, -0.65, 0.65)
		player.rotation.y = yaw
		camera_pivot.rotation.x = pitch
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not paused:
		fire_weapon()

func fire_weapon() -> void:
	if paused: return
	if ammo <= 0:
		play_sound("empty"); return
	ammo -= 1
	play_sound("shot")
	var center := get_viewport().get_visible_rect().size * 0.5
	var origin := camera.project_ray_origin(center)
	var end := origin + camera.project_ray_normal(center) * 55.0
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [player.get_rid()]
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result and result.collider is Zombie:
		result.collider.hit(48)
	_update_hud()

func reload_weapon() -> void:
	if paused: return
	var amount: int = min(12 - ammo, reserve)
	ammo += amount; reserve -= amount
	play_sound("reload")
	_update_hud()

func hurt_player(damage: int) -> void:
	health = max(0, health - damage)
	play_sound("hurt")
	if health == 0:
		health = 100
		player.position = Vector3(0, 1.1, -7)
	_update_hud()

func zombie_defeated(_zombie: Node, kind: int) -> void:
	kills += 1
	points += 300 if kind == Zombie.Kind.WAECHTER else 175 if kind == Zombie.Kind.RENNER else 100
	if mission_stage == 1 and kills >= 5: mission_stage = 2
	if mission_stage == 4 and kind == Zombie.Kind.WAECHTER: mission_stage = 5
	_update_hud()

func _update_mission_by_position() -> void:
	var z := player.position.z
	var old := mission_stage
	if mission_stage == 0 and z > 7: mission_stage = 1
	elif mission_stage == 2 and z > 39: mission_stage = 3
	elif mission_stage == 3 and z > 72: mission_stage = 4
	if mission_stage != old: _update_hud()

func toggle_settings() -> void:
	paused = not paused
	settings_panel.visible = paused

func play_sound(kind: String) -> void:
	if not sound_enabled or sound_playback == null: return
	var frequency := 85.0 if kind == "shot" else 210.0 if kind == "reload" else 55.0 if kind == "hurt" else 145.0 if kind == "empty" else 420.0
	var duration := 0.11 if kind == "shot" else 0.08
	var frames := PackedVector2Array()
	var count := int(22050.0 * duration)
	frames.resize(count)
	for index in count:
		var fade := 1.0 - float(index) / count
		var sample := sin(TAU * frequency * index / 22050.0) * 0.32 * fade
		frames[index] = Vector2(sample, sample)
	sound_playback.push_buffer(frames)

func _update_hud() -> void:
	hud.text = "LEBEN %d    MUNITION %d/%d    PUNKTE %d" % [health, ammo, reserve, points]
	var objective: String = objectives[min(mission_stage, objectives.size() - 1)]
	if mission_stage == 1: objective = "Sichere den Weg zur Apotheke (%d/5)." % min(kills, 5)
	objective_label.text = "MISSION: " + objective

func _button(text: String, position: Vector2, button_size: Vector2, color: Color) -> Button:
	var button := Button.new()
	button.text = text; button.position = position; button.size = button_size
	button.add_theme_font_size_override("font_size", 18)
	var style := StyleBoxFlat.new(); style.bg_color = color; style.corner_radius_top_left = 14; style.corner_radius_top_right = 14; style.corner_radius_bottom_left = 14; style.corner_radius_bottom_right = 14
	button.add_theme_stylebox_override("normal", style)
	return button

func _block(name: String, position: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new(); body.name = name; body.position = position
	var mesh := MeshInstance3D.new(); var box := BoxMesh.new(); box.size = size; mesh.mesh = box; mesh.material_override = _material(color, 0.9); body.add_child(mesh)
	var collision := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = size; collision.shape = shape; body.add_child(collision)
	add_child(body)

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new(); material.albedo_color = color; material.roughness = roughness
	return material
