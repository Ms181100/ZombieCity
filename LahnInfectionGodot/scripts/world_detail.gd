extends RefCounted

static func build(game: Node3D) -> void:
	# Strong visual landmarks so every new APK is immediately distinguishable.
	_road_markings(game)
	for z in range(-4, 101, 13):
		_lamp(game, Vector3(-8.0, 0, float(z)))
		_lamp(game, Vector3(8.0, 0, float(z + 6)))
	for z in [10.0, 47.0, 66.0]:
		_barrier(game, Vector3(-2.8, 0.35, z), -0.12)
		_barrier(game, Vector3(2.8, 0.35, z + 1.4), 0.10)
	for z in [4.0, 24.0, 53.0, 79.0, 94.0]:
		_debris(game, Vector3(-5.5, 0.15, z))
	for side in [-1, 1]:
		for index in range(9):
			_facade(game, side, float(index * 12 - 9), index)
	_landmark_board(game, "B49", Vector3(-6.4, 3.0, 5.0), Color("1766a5"), Vector2(2.8, 1.2))
	_landmark_board(game, "APOTHEKE", Vector3(-8.55, 4.4, 38.0), Color("16884a"), Vector2(5.2, 1.25))
	_cross(game, Vector3(-8.35, 5.7, 35.8))
	_pharmacy_front(game)
	_landmark_board(game, "FEUERWEHR", Vector3(8.05, 5.1, 84.0), Color("a82820"), Vector2(6.0, 1.3))
	_fire_station_details(game)
	for z in [18.0, 31.0, 58.0, 72.0]:
		_car_details(game, z)

static func _road_markings(game: Node3D) -> void:
	for z in range(-8, 104, 8):
		_box(game, Vector3(0, 0.035, float(z)), Vector3(0.18, 0.025, 4.0), Color("d8d5bd"), 0.75)
	for x in [-4.7, 4.7]:
		_box(game, Vector3(x, 0.04, 48), Vector3(0.12, 0.025, 112), Color("c7c5b2"), 0.8)
	# Large red-white emergency crossing near the fire station.
	for i in range(7):
		var c := Color("c83b32") if i % 2 == 0 else Color("e7e2d4")
		_box(game, Vector3(float(i - 3) * 1.2, 0.05, 76.0), Vector3(1.0, 0.03, 3.8), c, 0.7)

static func _facade(game: Node3D, side: int, z: float, index: int) -> void:
	var x := float(side) * 9.55
	var wall := Color("c7b99f") if index % 2 == 0 else Color("a99b83")
	_box(game, Vector3(x + float(side) * 0.18, 3.1, z), Vector3(0.35, 6.1, 9.0), wall)
	var beam := Color("291b14")
	for y in [1.1, 3.2, 5.25]:
		_box(game, Vector3(x, y, z), Vector3(0.14, 0.18, 8.4), beam)
	for dz in [-3.7, 0.0, 3.7]:
		_box(game, Vector3(x, 3.2, z + dz), Vector3(0.15, 5.5, 0.17), beam)
	for y in [2.0, 4.2]:
		for dz in [-2.25, 2.25]:
			_box(game, Vector3(x - float(side) * 0.10, y, z + dz), Vector3(0.09, 0.95, 1.35), Color("17303b"), 0.25)
	if index % 3 == 0:
		_box(game, Vector3(x - float(side) * 0.14, 1.15, z), Vector3(0.11, 2.0, 1.25), Color("35271e"))

static func _pharmacy_front(game: Node3D) -> void:
	_box(game, Vector3(-8.2, 2.2, 38.0), Vector3(0.18, 3.2, 7.5), Color("d9ded8"), 0.55)
	_box(game, Vector3(-8.05, 1.8, 36.0), Vector3(0.08, 2.5, 2.2), Color("15343a"), 0.2)
	_box(game, Vector3(-8.05, 1.8, 40.0), Vector3(0.08, 2.5, 2.2), Color("15343a"), 0.2)
	_box(game, Vector3(-7.95, 1.3, 38.0), Vector3(0.10, 2.5, 1.3), Color("31584b"), 0.35)

static func _lamp(game: Node3D, pos: Vector3) -> void:
	_box(game, pos + Vector3(0, 2.4, 0), Vector3(0.12, 4.8, 0.12), Color("20252a"))
	_box(game, pos + Vector3(0, 4.75, 0), Vector3(0.65, 0.14, 0.22), Color("20252a"))
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 4.55, 0)
	light.light_color = Color("e5c98b")
	light.light_energy = 1.15
	light.omni_range = 9.0
	light.shadow_enabled = false
	game.add_child(light)

static func _barrier(game: Node3D, pos: Vector3, rot: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = rot
	game.add_child(root)
	_box(root, Vector3(0, 0.45, 0), Vector3(4.5, 0.28, 0.18), Color("e1ded0"))
	for x in [-1.5, 0.0, 1.5]:
		_box(root, Vector3(x, 0.43, -0.10), Vector3(0.55, 0.30, 0.06), Color("c73c30"))
		_box(root, Vector3(x, -0.05, 0), Vector3(0.13, 0.85, 0.13), Color("393c3d"))

static func _debris(game: Node3D, pos: Vector3) -> void:
	_box(game, pos, Vector3(1.1, 0.18, 0.65), Color("3d3329"))
	_box(game, pos + Vector3(0.65, 0.10, 0.35), Vector3(0.55, 0.22, 0.45), Color("292b2c"))
	_box(game, pos + Vector3(-0.4, 0.22, -0.28), Vector3(0.35, 0.42, 0.30), Color("5a4936"))

static func _car_details(game: Node3D, z: float) -> void:
	var x := 3.2 if int(z) % 2 == 0 else -3.2
	var body_color := Color("7e2524") if int(z) % 3 == 0 else Color("26343d")
	_box(game, Vector3(x, 0.8, z), Vector3(2.2, 0.65, 4.1), body_color, 0.48)
	_box(game, Vector3(x, 1.35, z - 0.25), Vector3(1.75, 0.75, 2.1), body_color, 0.48)
	_box(game, Vector3(x, 1.48, z - 0.35), Vector3(1.45, 0.36, 1.1), Color("17232b"), 0.2)
	for dx in [-1.0, 1.0]:
		for dz in [-1.25, 1.25]:
			_box(game, Vector3(x + dx, 0.48, z + dz), Vector3(0.28, 0.58, 0.62), Color("111315"))

static func _fire_station_details(game: Node3D) -> void:
	_box(game, Vector3(8.35, 3.0, 84.0), Vector3(0.6, 6.0, 14.0), Color("d4d0c4"), 0.72)
	for z in [80.5, 84.0, 87.5]:
		_box(game, Vector3(7.95, 2.0, z), Vector3(0.18, 3.7, 2.7), Color("a92721"), 0.5)
		for y in [1.0, 2.0, 3.0]:
			_box(game, Vector3(7.82, y, z), Vector3(0.08, 0.08, 2.35), Color("e4ddd0"))
	# Emergency light mast.
	_box(game, Vector3(6.9, 2.4, 76.5), Vector3(0.16, 4.8, 0.16), Color("33383b"))
	_box(game, Vector3(6.9, 4.8, 76.5), Vector3(0.65, 0.25, 0.25), Color("185cb0"), 0.25)

static func _cross(game: Node3D, pos: Vector3) -> void:
	_box(game, pos, Vector3(0.18, 1.8, 0.48), Color("f0f4ed"), 0.35)
	_box(game, pos, Vector3(0.18, 0.48, 1.8), Color("f0f4ed"), 0.35)
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0.8, 0, 0)
	light.light_color = Color("54e487")
	light.light_energy = 2.0
	light.omni_range = 6.0
	game.add_child(light)

static func _landmark_board(game: Node3D, label_name: String, pos: Vector3, color: Color, size: Vector2) -> void:
	var board := _box(game, pos, Vector3(0.18, size.y, size.x), color, 0.38)
	board.name = label_name
	# Bright trim makes landmarks readable as shapes even before final text textures exist.
	_box(game, pos + Vector3(-0.11, size.y * 0.5, 0), Vector3(0.08, 0.08, size.x + 0.18), Color("f1eee1"))
	_box(game, pos + Vector3(-0.11, -size.y * 0.5, 0), Vector3(0.08, 0.08, size.x + 0.18), Color("f1eee1"))

static func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, roughness: float = 0.88) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	return mesh_instance
