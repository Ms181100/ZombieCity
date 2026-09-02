extends CharacterBody3D

enum Kind { SCHLURFER, RENNER, WAECHTER }

var kind: Kind = Kind.SCHLURFER
var target: CharacterBody3D
var game: Node
var health := 100
var speed := 1.5
var damage := 10
var attack_wait := 0.0
var visual_root: Node3D
var left_arm: MeshInstance3D
var right_arm: MeshInstance3D
var walk_time := 0.0

func setup(new_kind: Kind, player: CharacterBody3D, owner_game: Node) -> void:
	kind = new_kind
	target = player
	game = owner_game
	match kind:
		Kind.RENNER:
			health = 70; speed = 4.6; damage = 16
		Kind.WAECHTER:
			health = 260; speed = 2.0; damage = 25
		_:
			health = 100; speed = 1.45; damage = 10
	_build_body()

func _build_body() -> void:
	visual_root = Node3D.new()
	visual_root.name = "InfectedVisual"
	visual_root.rotation_degrees.x = -4.0 if kind == Kind.SCHLURFER else -9.0 if kind == Kind.RENNER else 0.0
	add_child(visual_root)

	var skin := Color("7d806b")
	var cloth := Color("4c5148") if kind == Kind.SCHLURFER else Color("6e332d") if kind == Kind.RENNER else Color("26344a")
	var dark := Color("252923")
	var scale_factor := 1.18 if kind == Kind.WAECHTER else 1.0

	_part("Torso", Vector3(0, 0.28, 0), Vector3(0.72, 0.92, 0.38) * scale_factor, cloth)
	_part("Bauch", Vector3(0, -0.30, 0), Vector3(0.58, 0.42, 0.34) * scale_factor, dark)
	_part("Kopf", Vector3(0, 1.02 * scale_factor, -0.03), Vector3(0.43, 0.48, 0.42) * scale_factor, skin)
	_part("LinkesBein", Vector3(-0.19 * scale_factor, -0.94 * scale_factor, 0), Vector3(0.25, 0.92, 0.27) * scale_factor, dark)
	_part("RechtesBein", Vector3(0.19 * scale_factor, -0.94 * scale_factor, 0), Vector3(0.25, 0.92, 0.27) * scale_factor, dark)
	left_arm = _part("LinkerArm", Vector3(-0.49 * scale_factor, 0.22 * scale_factor, -0.08), Vector3(0.22, 0.90, 0.22) * scale_factor, skin)
	right_arm = _part("RechterArm", Vector3(0.49 * scale_factor, 0.22 * scale_factor, -0.08), Vector3(0.22, 0.90, 0.22) * scale_factor, skin)
	left_arm.rotation_degrees.x = -24.0
	right_arm.rotation_degrees.x = -36.0

	if kind == Kind.WAECHTER:
		_part("PolizeiWeste", Vector3(0, 0.34, -0.23), Vector3(0.82, 0.72, 0.12), Color("111923"))
		_part("Helm", Vector3(0, 1.30, 0), Vector3(0.66, 0.22, 0.60), Color("111820"))
		_part("Visier", Vector3(0, 1.20, -0.31), Vector3(0.48, 0.16, 0.05), Color(0.12, 0.17, 0.19, 0.78))

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.48 if kind != Kind.WAECHTER else 0.65
	shape.height = 1.85 if kind != Kind.WAECHTER else 2.15
	collision.shape = shape
	add_child(collision)

func _part(part_name: String, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.position = pos
	part.material_override = _material(color, 0.88)
	visual_root.add_child(part)
	return part

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or game.paused:
		velocity = Vector3.ZERO
		return
	attack_wait -= delta
	var difference := target.global_position - global_position
	difference.y = 0.0
	if difference.length_squared() > 32.0 * 32.0:
		velocity = Vector3.ZERO
		return
	if difference.length() > 1.55:
		velocity = difference.normalized() * speed
		look_at(global_position + difference, Vector3.UP)
		move_and_slide()
		_animate_walk(delta)
	elif attack_wait <= 0.0:
		attack_wait = 1.15
		game.hurt_player(damage)

func _animate_walk(delta: float) -> void:
	walk_time += delta * (8.0 if kind == Kind.RENNER else 4.0)
	if visual_root:
		visual_root.position.y = sin(walk_time * 2.0) * 0.035
	if left_arm and right_arm:
		left_arm.rotation_degrees.x = -25.0 + sin(walk_time) * 18.0
		right_arm.rotation_degrees.x = -25.0 - sin(walk_time) * 18.0

func hit(amount: int) -> void:
	health -= amount
	game.play_sound("hit")
	if visual_root:
		var tween := create_tween()
		tween.tween_property(visual_root, "scale", Vector3(1.08, 0.94, 1.08), 0.05)
		tween.tween_property(visual_root, "scale", Vector3.ONE, 0.10)
	if health <= 0:
		game.zombie_defeated(self, kind)
		queue_free()

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat
