extends Node3D

var player
var camera
var pivot
var hud
var mission
var menu
var settings
var move_axis = Vector2.ZERO
var yaw = 0.0
var pitch = -0.18
var health = 100
var ammo = 12
var reserve = 60
var score = 0
var kills = 0
var started = false
var zombies = []
var fire_audio
var hit_audio
var reload_audio
var zombie_audio

func _ready():
	build_ui()
	build_audio()
	build_world()
	build_player()
	for index in range(9):
		spawn_zombie(index % 3, Vector3(-7.0 + float(index % 5) * 3.0, 0.9, -10.0 - float(index) * 4.0))
	update_hud()

func make_material(color_value):
	var result = StandardMaterial3D.new()
	result.albedo_color = color_value
	result.roughness = 0.9
	return result

func add_body_part(parent_node, part_size, part_position, color_value):
	var part = MeshInstance3D.new()
	var part_mesh = BoxMesh.new()
	part_mesh.size = part_size
	part_mesh.material = make_material(color_value)
	part.mesh = part_mesh
	part.position = part_position
	parent_node.add_child(part)
	return part

func add_head(parent_node, head_position, color_value):
	var head = MeshInstance3D.new()
	var head_mesh = SphereMesh.new()
	head_mesh.radius = 0.28
	head_mesh.height = 0.56
	head_mesh.material = make_material(color_value)
	head.mesh = head_mesh
	head.position = head_position
	parent_node.add_child(head)

func add_box(position, size, color_value, add_collision = true):
	var mesh_node = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	box_mesh.material = make_material(color_value)
	mesh_node.mesh = box_mesh
	mesh_node.position = position
	add_child(mesh_node)
	if add_collision:
		var body = StaticBody3D.new()
		var shape_node = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = size
		shape_node.shape = shape
		body.add_child(shape_node)
		mesh_node.add_child(body)

func build_world():
	var world = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("081019")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("91a5b5")
	environment.ambient_light_energy = 0.65
	world.environment = environment
	add_child(world)
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55.0, -30.0, 0.0)
	light.light_energy = 1.2
	add_child(light)
	add_box(Vector3(0.0, -0.5, -14.0), Vector3(44.0, 1.0, 95.0), Color("252729"))
	add_box(Vector3(-6.0, 0.08, -14.0), Vector3(4.0, 0.16, 95.0), Color("77736d"), false)
	add_box(Vector3(6.0, 0.08, -14.0), Vector3(4.0, 0.16, 95.0), Color("77736d"), false)
	for side in [-1, 1]:
		for z_value in range(-50, 27, 12):
			var height = 7.0 + float(abs(z_value) % 6)
			add_box(Vector3(float(side) * 13.0, height / 2.0, float(z_value)), Vector3(10.0, height, 10.0), Color("3b3d40"))
	for line_z in range(-48, 25, 9):
		add_box(Vector3(-2.7, 0.11, float(line_z)), Vector3(0.14, 0.03, 3.5), Color("e4ddc6"), false)

func build_player():
	player = CharacterBody3D.new()
	player.position = Vector3(0.0, 1.0, 18.0)
	add_child(player)
	var collision = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.height = 1.8
	shape.radius = 0.42
	collision.shape = shape
	player.add_child(collision)
	add_body_part(player, Vector3(0.72, 0.82, 0.34), Vector3(0.0, 0.35, 0.0), Color("263f58"))
	add_head(player, Vector3(0.0, 1.02, 0.0), Color("c58f6a"))
	add_body_part(player, Vector3(0.22, 0.82, 0.24), Vector3(-0.22, -0.48, 0.0), Color("20252b"))
	add_body_part(player, Vector3(0.22, 0.82, 0.24), Vector3(0.22, -0.48, 0.0), Color("20252b"))
	add_body_part(player, Vector3(0.2, 0.78, 0.22), Vector3(-0.48, 0.32, 0.0), Color("263f58"))
	add_body_part(player, Vector3(0.2, 0.78, 0.22), Vector3(0.48, 0.32, 0.0), Color("263f58"))
	add_body_part(player, Vector3(0.12, 0.16, 0.9), Vector3(0.43, 0.25, -0.48), Color("27292b"))
	pivot = Node3D.new()
	pivot.position = Vector3(0.0, 1.45, 0.0)
	player.add_child(pivot)
	var arm = SpringArm3D.new()
	arm.spring_length = 4.3
	pivot.add_child(arm)
	camera = Camera3D.new()
	camera.current = true
	arm.add_child(camera)

func spawn_zombie(kind, location):
	var zombie = CharacterBody3D.new()
	zombie.position = location
	zombie.set_meta("hp", [100, 65, 240][kind])
	zombie.set_meta("speed", [1.5, 3.0, 0.8][kind])
	add_child(zombie)
	zombies.append(zombie)
	var collision = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.height = [1.8, 1.65, 2.2][kind]
	shape.radius = [0.38, 0.33, 0.62][kind]
	collision.shape = shape
	zombie.add_child(collision)
	var clothes = [Color("3f543c"), Color("6a4038"), Color("303b34")][kind]
	var skin = [Color("77806a"), Color("86635b"), Color("566657")][kind]
	var scale_value = [1.0, 0.9, 1.25][kind]
	add_body_part(zombie, Vector3(0.72, 0.82, 0.34) * scale_value, Vector3(0.0, 0.35, 0.0), clothes)
	add_head(zombie, Vector3(0.0, 1.02 * scale_value, 0.0), skin)
	add_body_part(zombie, Vector3(0.2, 0.85, 0.22) * scale_value, Vector3(-0.22, -0.48, 0.0), Color("252525"))
	add_body_part(zombie, Vector3(0.2, 0.85, 0.22) * scale_value, Vector3(0.22, -0.48, 0.0), Color("252525"))
	var left_arm = add_body_part(zombie, Vector3(0.18, 0.85, 0.2) * scale_value, Vector3(-0.5, 0.32, -0.22), skin)
	var right_arm = add_body_part(zombie, Vector3(0.18, 0.85, 0.2) * scale_value, Vector3(0.5, 0.32, -0.22), skin)
	left_arm.rotation_degrees.x = 62.0
	right_arm.rotation_degrees.x = 62.0

func add_label(parent, text_value, position, size, font_size):
	var label = Label.new()
	label.text = text_value
	label.position = position
	label.size = size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func build_ui():
	var layer = CanvasLayer.new()
	add_child(layer)
	hud = add_label(layer, "LEBEN 100", Vector2(15.0, 15.0), Vector2(420.0, 40.0), 20)
	hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	mission = add_label(layer, "MISSION", Vector2(330.0, 15.0), Vector2(620.0, 45.0), 20)
	add_move_button(layer, "VOR", Vector2(90.0, 520.0), Vector2(0.0, -1.0))
	add_move_button(layer, "ZURUECK", Vector2(90.0, 630.0), Vector2(0.0, 1.0))
	add_move_button(layer, "LINKS", Vector2(5.0, 575.0), Vector2(-1.0, 0.0))
	add_move_button(layer, "RECHTS", Vector2(175.0, 575.0), Vector2(1.0, 0.0))
	var fire = Button.new()
	fire.text = "FEUER"
	fire.position = Vector2(1090.0, 570.0)
	fire.size = Vector2(150.0, 110.0)
	fire.pressed.connect(shoot)
	layer.add_child(fire)
	var reload_button = Button.new()
	reload_button.text = "LADEN"
	reload_button.position = Vector2(950.0, 620.0)
	reload_button.size = Vector2(120.0, 70.0)
	reload_button.pressed.connect(reload_weapon)
	layer.add_child(reload_button)
	var options = Button.new()
	options.text = "OPTIONEN"
	options.position = Vector2(1110.0, 18.0)
	options.size = Vector2(145.0, 55.0)
	options.pressed.connect(toggle_settings)
	layer.add_child(options)
	menu = ColorRect.new()
	menu.color = Color(0.02, 0.025, 0.03, 1.0)
	menu.position = Vector2.ZERO
	menu.size = Vector2(1280.0, 720.0)
	layer.add_child(menu)
	var title_background = TextureRect.new()
	title_background.texture = load("res://assets/backgrounds/germany_fallen_title.jpg")
	title_background.position = Vector2.ZERO
	title_background.size = Vector2(1280.0, 720.0)
	title_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	menu.add_child(title_background)
	var title_shadow = ColorRect.new()
	title_shadow.color = Color(0.0, 0.0, 0.0, 0.42)
	title_shadow.position = Vector2.ZERO
	title_shadow.size = Vector2(1280.0, 720.0)
	menu.add_child(title_shadow)
	add_label(menu, "ZOMBIE CITY", Vector2(0.0, 115.0), Vector2(1280.0, 90.0), 68)
	add_label(menu, "DEUTSCHLAND IST GEFALLEN", Vector2(0.0, 220.0), Vector2(1280.0, 45.0), 25)
	var age = add_label(menu, "AB 18 - STARKE GEWALTDARSTELLUNG", Vector2(0.0, 280.0), Vector2(1280.0, 40.0), 20)
	age.add_theme_color_override("font_color", Color("d43737"))
	var play = Button.new()
	play.text = "NEUES SPIEL"
	play.position = Vector2(490.0, 380.0)
	play.size = Vector2(300.0, 90.0)
	play.pressed.connect(start_game)
	menu.add_child(play)
	settings = ColorRect.new()
	settings.color = Color(0.03, 0.04, 0.05, 0.98)
	settings.position = Vector2(340.0, 120.0)
	settings.size = Vector2(600.0, 480.0)
	settings.visible = false
	layer.add_child(settings)
	add_label(settings, "EINSTELLUNGEN", Vector2(0.0, 35.0), Vector2(600.0, 50.0), 30)
	var close = Button.new()
	close.text = "ZURUECK"
	close.position = Vector2(200.0, 360.0)
	close.size = Vector2(200.0, 65.0)
	close.pressed.connect(toggle_settings)
	settings.add_child(close)

func add_move_button(parent, text_value, position, direction):
	var button = Button.new()
	button.text = text_value
	button.position = position
	button.size = Vector2(110.0, 60.0)
	button.button_down.connect(begin_move.bind(direction))
	button.button_up.connect(end_move.bind(direction))
	parent.add_child(button)

func begin_move(direction):
	move_axis += direction

func end_move(direction):
	move_axis -= direction

func start_game():
	started = true
	menu.visible = false
	zombie_audio.play()

func toggle_settings():
	settings.visible = not settings.visible

func reload_weapon():
	var amount = min(12 - ammo, reserve)
	ammo += amount
	reserve -= amount
	reload_audio.play()
	update_hud()

func shoot():
	if not started or settings.visible:
		return
	if ammo <= 0:
		reload_weapon()
		return
	ammo -= 1
	fire_audio.play()
	var ray_end = camera.global_position - camera.global_basis.z * 80.0
	var query = PhysicsRayQueryParameters3D.create(camera.global_position, ray_end)
	query.exclude = [player]
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	if hit and hit.collider in zombies:
		hit_audio.play()
		var zombie = hit.collider
		zombie.set_meta("hp", int(zombie.get_meta("hp")) - 50)
		if int(zombie.get_meta("hp")) <= 0:
			zombies.erase(zombie)
			zombie.queue_free()
			score += 100
			kills += 1
	update_hud()

func make_sound(frequency, duration, noise_amount):
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var sample_count = int(22050.0 * duration)
	var bytes = PackedByteArray()
	bytes.resize(sample_count * 2)
	for sample_index in range(sample_count):
		var time_value = float(sample_index) / 22050.0
		var fade = 1.0 - float(sample_index) / float(sample_count)
		var wave = sin(TAU * frequency * time_value)
		var noise = randf_range(-1.0, 1.0) * noise_amount
		var value = int(clamp((wave * (1.0 - noise_amount) + noise) * fade, -1.0, 1.0) * 32767.0)
		bytes[sample_index * 2] = value & 255
		bytes[sample_index * 2 + 1] = (value >> 8) & 255
	stream.data = bytes
	return stream

func add_audio(stream, volume):
	var audio = AudioStreamPlayer.new()
	audio.stream = stream
	audio.volume_db = volume
	add_child(audio)
	return audio

func build_audio():
	fire_audio = add_audio(make_sound(90.0, 0.16, 0.72), -3.0)
	hit_audio = add_audio(make_sound(55.0, 0.12, 0.55), -7.0)
	reload_audio = add_audio(make_sound(720.0, 0.13, 0.18), -8.0)
	zombie_audio = add_audio(make_sound(74.0, 0.75, 0.38), -10.0)

func _unhandled_input(event):
	if event is InputEventScreenDrag and event.position.x > 400.0 and not settings.visible:
		yaw -= event.relative.x * 0.004
		pitch = clamp(pitch - event.relative.y * 0.004, -0.8, 0.35)

func update_hud():
	hud.text = "LEBEN %d   MUNITION %d/%d   PUNKTE %d" % [health, ammo, reserve, score]
	if kills < 5:
		mission.text = "MISSION: Sichere den Weg zur Apotheke (%d/5)" % kills
	else:
		mission.text = "MISSION ERFUELLT"

func _physics_process(delta):
	if not started or settings.visible or player == null:
		return
	pivot.rotation = Vector3(pitch, yaw, 0.0)
	player.rotation.y = yaw
	var direction = Vector3(move_axis.x, 0.0, move_axis.y).normalized().rotated(Vector3.UP, yaw)
	player.velocity = Vector3(direction.x * 4.5, -3.0, direction.z * 4.5)
	player.move_and_slide()
	for zombie in zombies:
		if not is_instance_valid(zombie):
			continue
		var difference = player.global_position - zombie.global_position
		difference.y = 0.0
		if difference.length() < 24.0:
			zombie.velocity = difference.normalized() * float(zombie.get_meta("speed"))
			zombie.look_at(player.global_position, Vector3.UP)
			zombie.move_and_slide()
		if difference.length() < 1.25:
			health = max(0, health - int(18.0 * delta))
	update_hud()
