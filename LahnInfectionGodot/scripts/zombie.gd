extends CharacterBody3D

enum Kind { SCHLURFER, RENNER, WAECHTER }

var kind: Kind = Kind.SCHLURFER
var target: CharacterBody3D
var game: Node
var health := 100
var speed := 1.5
var damage := 10
var attack_wait := 0.0

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
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.48 if kind != Kind.WAECHTER else 0.65
	capsule.height = 1.85 if kind != Kind.WAECHTER else 2.15
	body.mesh = capsule
	var material := StandardMaterial3D.new()
	material.roughness = 0.9
	material.albedo_color = Color("94382f") if kind == Kind.RENNER else Color("26344a") if kind == Kind.WAECHTER else Color("31543b")
	body.material_override = material
	add_child(body)
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = capsule.radius
	shape.height = capsule.height
	collision.shape = shape
	add_child(collision)
	if kind == Kind.WAECHTER:
		var helmet := MeshInstance3D.new()
		helmet.mesh = BoxMesh.new()
		helmet.scale = Vector3(0.85, 0.22, 0.85)
		helmet.position.y = 1.0
		helmet.material_override = _material(Color("17202c"), 0.55)
		add_child(helmet)

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
	elif attack_wait <= 0.0:
		attack_wait = 1.15
		game.hurt_player(damage)

func hit(amount: int) -> void:
	health -= amount
	game.play_sound("hit")
	if health <= 0:
		game.zombie_defeated(self, kind)
		queue_free()

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat
