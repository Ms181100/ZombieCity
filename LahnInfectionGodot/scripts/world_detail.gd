extends RefCounted

static func build(game: Node3D) -> void:
	# B49 corridor details: barriers, lamps, road furniture, Fachwerk fronts and landmarks.
	for z in range(-4, 101, 13):
		_lamp(game, Vector3(-8.0, 0, float(z)))
		_lamp(game, Vector3(8.0, 0, float(z + 6)))
	for z in [10.0, 47.0, 66.0]:
		_barrier(game, Vector3(-2.8, 0.35, z), -0.12)
		_barrier(game, Vector3(2.8, 0.35, z + 1.4), 0.10)
	for z in [4.0, 24.0, 53.0, 79.0, 94.0]:
		_debris(game, Vector3(-5.5, 0.15, z))
	# Fachwerk-like facade beams and windows on both street sides.
	for side in [-1, 1]:
		for index in range(9):
			var z := float(index * 12 - 9)
			_facade(game, side, z, index)
	_sign(game, "B49", Vector3(-6.8, 2.15, 3.0), Color("215a8d"), Vector3(1.45, 0.72, 0.10))
	_sign(game, "APOTHEKE", Vector3(-8.72, 3.6, 38.0), Color("1e8b4b"), Vector3(0.12, 1.25, 2.8))
	_cross(game, Vector3(-8.55, 4.25, 35.8))
	_sign(game, "FEUERWEHR", Vector3(8.15, 4.4, 84.0), Color("a52820"), Vector3(0.12, 1.0, 3.6))
	_fire_station_details(game)
	for z in [18.0, 31.0, 58.0, 72.0]:
		_car_details(game, z)

static func _facade(game: Node3D, side: int, z: float, index: int) -> void:
	var x := float(side) * 9.55
	var beam := Color("241914")
	for y in [1.2, 3.2, 5.2]:
		_box(game, Vector3(x, y, z), Vector3(0.13, 0.18, 8.0), beam)
	for dz in [-3.4, 0.0, 3.4]:
		_box(game, Vector3(x, 3.2, z + dz), Vector3(0.14, 5.4, 0.16), beam)
	for y in [2.0, 4.1]:
		for dz in [-2.0, 2.0]:
			_box(game, Vector3(x - float(side) * 0.08, y, z + dz), Vector3(0.08, 0.82, 1.15), Color("17222b"), 0.28)
	if index % 3 == 0:
		_box(game, Vector3(x - float(side) * 0.12, 1.15, z), Vector3(0.10, 1.9, 1.15), Color("30251f"))

static func _lamp(game: Node3D, pos: Vector3) -> void:
	_box(game, pos + Vector3(0, 2.4, 0), Vector3(0.12, 4.8, 0.12), Color("20252a"))
	_box(game, pos + Vector3(0, 4.75, 0), Vector3(0.65, 0.14, 0.22), Color("20252a"))
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 4.55, 0)
	light.light_color = Color("e5c98b")
	light.light_energy = 0.75
	light.omni_range = 7.5
	light.shadow_enabled = false
	game.add_child(light)

static func _barrier(game: Node3D, pos: Vector3, rot: float) -> void:
	var root := Node3D.new(); root.position = pos; root.rotation.y = rot; game.add_child(root)
	_box(root, Vector3(0, 0.45, 0), Vector3(4.5, 0.28, 0.18), Color("d7d4c7"))
	for x in [-1.5, 0.0, 1.5]:
		_box(root, Vector3(x, 0.43, -0.10), Vector3(0.55, 0.30, 0.06), Color("b83b2f"))
		_box(root, Vector3(x, -0.05, 0), Vector3(0.13, 0.85, 0.13), Color("393c3d"))

static func _debris(game: Node3D, pos: Vector3) -> void:
	_box(game, pos, Vector3(1.1, 0.18, 0.65), Color("3d3329"))
	_box(game, pos + Vector3(0.65, 0.10, 0.35), Vector3(0.55, 0.22, 0.45), Color("292b2c"))
	_box(game, pos + Vector3(-0.4, 0.22, -0.28), Vector3(0.35, 0.42, 0.30), Color("5a4936"))

static func _car_details(game: Node3D, z: float) -> void:
	var x := 3.2 if int(z) % 2 == 0 else -3.2
	_box(game, Vector3(x, 1.30, z - 0.25), Vector3(1.75, 0.58, 2.1), Color("252c32"))
	_box(game, Vector3(x, 1.45, z - 0.35), Vector3(1.45, 0.34, 1.1), Color("17232b"), 0.32)
	for dx in [-1.0, 1.0]:
		for dz in [-1.25, 1.25]:
			_box(game, Vector3(x + dx, 0.48, z + dz), Vector3(0.28, 0.58, 0.62), Color("111315"))

static func _fire_station_details(game: Node3D) -> void:
	for z in [80.5, 84.0, 87.5]:
		_box(game, Vector3(8.15, 2.0, z), Vector3(0.14, 3.5, 2.5), Color("30363a"))
		_box(game, Vector3(8.05, 2.0, z), Vector3(0.08, 3.0, 2.05), Color("8c2721"))
	_box(game, Vector3(6.9, 0.55, 76.5), Vector3(1.5, 1.0, 1.1), Color("34383b"))

static func _cross(game: Node3D, pos: Vector3) -> void:
	_box(game, pos, Vector3(0.12, 1.3, 0.34), Color("e8eee9"))
	_box(game, pos, Vector3(0.12, 0.34, 1.3), Color("e8eee9"))

static func _sign(game: Node3D, label_name: String, pos: Vector3, color: Color, size: Vector3) -> void:
	var sign := _box(game, pos, size, color, 0.42)
	sign.name = label_name

static func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, roughness: float = 0.88) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new(); mesh.size = size; mesh_instance.mesh = mesh
	mesh_instance.position = pos
	var material := StandardMaterial3D.new(); material.albedo_color = color; material.roughness = roughness
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	return mesh_instance
