extends Node3D

var player: CharacterBody3D
var camera: Camera3D
var hp := 100
var ammo := 30
var score := 0
var started := false

func _ready() -> void:
	build_world()
	build_ui()

func box(parent: Node, pos: Vector3, size: Vector3, color: Color, collision := true) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mesh.material = mat
	mesh_node.mesh = mesh
	mesh_node.position = pos
	parent.add_child(mesh_node)
	if collision:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var form := BoxShape3D.new()
		form.size = size
		shape.shape = form
		body.add_child(shape)
		mesh_node.add_child(body)
	return mesh_node

func build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("05080d")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("637080")
	e.ambient_light_energy = 0.35
	e.fog_enabled = true
	e.fog_light_color = Color("151a20")
	e.fog_density = 0.025
	env.environment = e
	add_child(env)
	var moon := DirectionalLight3D.new()
	moon.light_color = Color("9ab5d5")
	moon.light_energy = 1.1
	moon.rotation_degrees = Vector3(-55, -25, 0)
	moon.shadow_enabled = true
	add_child(moon)
	box(self, Vector3(0,-0.5,0), Vector3(50,1,70), Color("25282a"))
	for side in [-1,1]:
		for z in range(-28,29,9):
			var height := 7.0 + float(abs(z)%5)
			box(self, Vector3(side*13,height/2,z), Vector3(12,height,7), Color("292d31"))
	for z in range(-25,26,10):
		box(self,Vector3(-4,0.35,z),Vector3(1.8,0.7,3.8),Color("461919"))
	player = CharacterBody3D.new()
	player.position = Vector3(0,1,18)
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new(); capsule.height=1.8; capsule.radius=0.4
	collider.shape = capsule; player.add_child(collider); add_child(player)
	camera = Camera3D.new(); camera.position=Vector3(0,0.65,0); camera.current=true; player.add_child(camera)
	var gun := box(camera,Vector3(0.32,-0.28,-0.65),Vector3(0.18,0.22,0.75),Color("16191b"),false)
	gun.rotation_degrees.x=-5

func build_ui() -> void:
	var layer := CanvasLayer.new(); add_child(layer)
	var shade := ColorRect.new(); shade.color=Color(0,0,0,0.92); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); layer.add_child(shade)
	var title := Label.new(); title.text="ZOMBIE CITY"; title.add_theme_font_size_override("font_size",72); title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; title.position=Vector2(0,130); title.size=Vector2(1280,100); shade.add_child(title)
	var warning := Label.new(); warning.text="AB 18 • ENTHÄLT STARKE GEWALTDARSTELLUNG"; warning.add_theme_color_override("font_color",Color("c62424")); warning.add_theme_font_size_override("font_size",24); warning.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; warning.position=Vector2(0,245); warning.size=Vector2(1280,50); shade.add_child(warning)
	var play := Button.new(); play.text="SPIELEN"; play.position=Vector2(490,380); play.size=Vector2(300,95); play.add_theme_font_size_override("font_size",34); shade.add_child(play)
	play.pressed.connect(func(): started=true; shade.visible=false)
	var hud := Label.new(); hud.name="HUD"; hud.position=Vector2(24,20); hud.add_theme_font_size_override("font_size",24); layer.add_child(hud)
	var cross := Label.new(); cross.text="+"; cross.position=Vector2(625,330); cross.add_theme_font_size_override("font_size",30); layer.add_child(cross)

func _physics_process(delta: float) -> void:
	if not started: return
	var input := Input.get_vector("move_left","move_right","move_forward","move_back")
	var dir := (player.transform.basis * Vector3(input.x,0,input.y)).normalized()
	player.velocity.x=dir.x*5.0; player.velocity.z=dir.z*5.0; player.velocity.y=-2.0
	player.move_and_slide()
	var hud := get_node("CanvasLayer/HUD") as Label
	hud.text="LEBEN %d     MUNITION %d     PUNKTE %d" % [hp,ammo,score]

