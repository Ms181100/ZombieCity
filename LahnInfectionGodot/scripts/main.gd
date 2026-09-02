extends Node3D

const Zombie = preload("res://scripts/zombie.gd")
const Joystick = preload("res://scripts/joystick.gd")
const MobileHUD = preload("res://scripts/mobile_hud.gd")
const WorldDetail = preload("res://scripts/world_detail.gd")

var player: CharacterBody3D
var player_visual: Node3D
var camera: Camera3D
var camera_pivot: Node3D
var joystick: Control
var mobile_hud: CanvasLayer
var settings_panel: PanelContainer
var health := 100
var ammo := 12
var reserve := 48
var kills := 0
var mission_stage := 0
var yaw := 0.0
var pitch := -0.16
var look_finger := -1
var paused := false
var sensitivity := 0.0045
var dodge_cooldown := 0.0
var generator_one := false
var generator_two := false
var objectives := ["Verlasse den Keller und erreiche die B49.", "Sichere den Weg zur Apotheke (0/5).", "Nimm das Medikit in der Apotheke.", "Erreiche die Feuerwehrwache.", "Besiege den Wächter vor der Wache.", "Starte Generator 1.", "Starte Generator 2.", "Sende das letzte Signal über Funk.", "SIGNAL GESENDET – Mission abgeschlossen."]

func _ready() -> void:
	_build_environment()
	_build_player()
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
	_block("B49", Vector3(0,-0.3,45), Vector3(14,0.5,112), Color("17191d"))
	for side in [-1,1]:
		_block("Gehweg", Vector3(side*8.5,0,45), Vector3(3,0.35,112), Color("53565a"))
		for index in range(10):
			var h := 7.0 + float(index%3)*1.6
			_block("Haus", Vector3(side*12.2,h/2.0,index*12.0-10.0), Vector3(5.2,h,10.5), Color("49352b"))
	_block("APOTHEKE", Vector3(-11.5,2.8,38), Vector3(5.5,5.5,11), Color("31563d"))
	_block("FEUERWEHR", Vector3(11.5,3.2,84), Vector3(6.5,6.5,14), Color("6c211c"))
	WorldDetail.build(self)
	_marker("MEDIKIT", Vector3(-6.8,0.55,38), Color("38d66b"))
	_marker("GENERATOR 1", Vector3(5.8,0.75,79), Color("e6b73d"))
	_marker("GENERATOR 2", Vector3(5.8,0.75,88), Color("e6b73d"))
	_marker("FUNKGERAET", Vector3(3.8,1.0,94), Color("49a8e8"))

func _marker(label_text:String, pos:Vector3, color:Color) -> void:
	var root := Node3D.new(); root.position=pos; root.name=label_text; add_child(root)
	var mesh := MeshInstance3D.new(); var box:=BoxMesh.new(); box.size=Vector3(0.8,0.8,0.8); mesh.mesh=box
	var mat:=StandardMaterial3D.new(); mat.albedo_color=color; mat.emission_enabled=true; mat.emission=color; mat.emission_energy_multiplier=1.6; mesh.material_override=mat; root.add_child(mesh)
	var label:=Label3D.new(); label.text=label_text; label.font_size=32; label.position=Vector3(0,1.0,0); label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; label.modulate=Color.WHITE; root.add_child(label)

func _build_player() -> void:
	player=CharacterBody3D.new(); player.position=Vector3(0,1.1,-7); add_child(player)
	var collision:=CollisionShape3D.new(); var capsule:=CapsuleShape3D.new(); capsule.radius=0.45; capsule.height=1.8; collision.shape=capsule; player.add_child(collision)
	player_visual=Node3D.new(); player.add_child(player_visual)
	_part(Vector3(0,0.25,0),Vector3(0.72,0.9,0.38),Color("263d50")); _part(Vector3(0,1.0,0),Vector3(0.44,0.48,0.42),Color("b58b70")); _part(Vector3(-0.25,-0.7,0),Vector3(0.28,1.05,0.3),Color("24282d")); _part(Vector3(0.25,-0.7,0),Vector3(0.28,1.05,0.3),Color("24282d")); _part(Vector3(0.42,0.12,-0.38),Vector3(0.12,0.14,0.72),Color("111417"))
	camera_pivot=Node3D.new(); camera_pivot.position=Vector3(0,1.4,0); player.add_child(camera_pivot)
	camera=Camera3D.new(); camera.position=Vector3(0.85,0.65,4.2); camera.fov=64; camera_pivot.add_child(camera)

func _part(pos:Vector3,size:Vector3,color:Color)->void:
	var m:=MeshInstance3D.new(); var b:=BoxMesh.new(); b.size=size; m.mesh=b; m.position=pos; m.material_override=_material(color,0.82); player_visual.add_child(m)

func _build_ui()->void:
	var controls:=CanvasLayer.new(); controls.layer=10; add_child(controls); joystick=Joystick.new(); joystick.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); controls.add_child(joystick)
	mobile_hud=MobileHUD.new(); mobile_hud.layer=20; mobile_hud.fire_pressed.connect(fire_weapon); mobile_hud.reload_pressed.connect(reload_weapon); mobile_hud.dodge_pressed.connect(dodge); mobile_hud.interact_pressed.connect(interact); mobile_hud.pause_pressed.connect(toggle_settings); add_child(mobile_hud)
	var layer:=CanvasLayer.new(); layer.layer=30; add_child(layer); settings_panel=PanelContainer.new(); settings_panel.set_anchors_preset(Control.PRESET_CENTER); settings_panel.position=Vector2(-250,-180); settings_panel.size=Vector2(500,360); settings_panel.visible=false; layer.add_child(settings_panel)
	var box:=VBoxContainer.new(); settings_panel.add_child(box); var title:=Label.new(); title.text="LAHN-INFECTION\nPAUSE"; title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size",28); box.add_child(title)
	var fps:=OptionButton.new(); fps.add_item("30 FPS",30); fps.add_item("60 FPS",60); fps.add_item("120 FPS",120); fps.selected=1; fps.item_selected.connect(func(i): Engine.max_fps=fps.get_item_id(i)); box.add_child(fps)
	var slider:=HSlider.new(); slider.min_value=0.002; slider.max_value=0.009; slider.value=sensitivity; slider.value_changed.connect(func(v): sensitivity=v); box.add_child(slider)
	var back:=Button.new(); back.text="WEITERSPIELEN"; back.custom_minimum_size.y=60; back.pressed.connect(toggle_settings); box.add_child(back)

func _spawn_zombies()->void:
	for index in range(15):
		var z:=Zombie.new(); var kind:=Zombie.Kind.RENNER if index in [5,10] else Zombie.Kind.WAECHTER if index==14 else Zombie.Kind.SCHLURFER; z.position=Vector3((-1 if index%2==0 else 1)*(2.2+index%3),1.0,12.0+index*5.2); add_child(z); z.setup(kind,player,self)

func _physics_process(delta:float)->void:
	if paused:return
	dodge_cooldown=maxf(0.0,dodge_cooldown-delta)
	var input_vector:Vector2=joystick.value
	var forward:=-camera.global_transform.basis.z; forward.y=0; forward=forward.normalized(); var right:=camera.global_transform.basis.x; right.y=0; right=right.normalized()
	var direction:=(right*input_vector.x+forward*-input_vector.y).normalized()
	var speed:=5.8 if input_vector.length()>0.92 else 3.4; player.velocity.x=direction.x*speed; player.velocity.z=direction.z*speed; player.velocity.y=-2.0 if player.is_on_floor() else player.velocity.y-18.0*delta; player.move_and_slide()
	if direction.length()>0.1: player_visual.rotation.y=lerp_angle(player_visual.rotation.y,atan2(-direction.x,-direction.z),delta*10.0)
	_update_position_stage()

func _unhandled_input(event:InputEvent)->void:
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x>get_viewport().get_visible_rect().size.x*0.48 and look_finger<0: look_finger=event.index
		elif not event.pressed and event.index==look_finger: look_finger=-1
	elif event is InputEventScreenDrag and event.index==look_finger and not paused:
		yaw-=event.relative.x*sensitivity; pitch=clamp(pitch-event.relative.y*sensitivity,-0.65,0.65); camera_pivot.rotation.y=yaw; camera_pivot.rotation.x=pitch

func fire_weapon()->void:
	if paused:return
	if ammo<=0:return
	ammo-=1; var center:=get_viewport().get_visible_rect().size*0.5; var origin:=camera.project_ray_origin(center); var end:=origin+camera.project_ray_normal(center)*55.0; var query:=PhysicsRayQueryParameters3D.create(origin,end); query.exclude=[player.get_rid()]; var result:=get_world_3d().direct_space_state.intersect_ray(query); if result and result.collider is Zombie: result.collider.hit(48); _update_hud()

func reload_weapon()->void:
	var amount:int=min(12-ammo,reserve); ammo+=amount; reserve-=amount; _update_hud()

func dodge()->void:
	if paused or dodge_cooldown>0:return
	var dir:=-camera.global_transform.basis.z; dir.y=0; dir=dir.normalized(); player.velocity.x=dir.x*10.0; player.velocity.z=dir.z*10.0; player.move_and_slide(); dodge_cooldown=0.8

func interact()->void:
	if paused:return
	var z:=player.position.z
	if mission_stage==2 and abs(z-38.0)<7.0: health=min(100,health+45); mission_stage=3
	elif mission_stage==5 and abs(z-79.0)<5.0: generator_one=true; mission_stage=6
	elif mission_stage==6 and generator_one and abs(z-88.0)<5.0: generator_two=true; mission_stage=7
	elif mission_stage==7 and generator_two and abs(z-94.0)<6.0: mission_stage=8
	_update_hud()

func hurt_player(damage:int)->void:
	health=max(0,health-damage); if mobile_hud: mobile_hud.flash_damage(); if health==0: health=100; player.position=Vector3(0,1.1,-7); _update_hud()

func zombie_defeated(_zombie:Node,kind:int)->void:
	kills+=1
	if mission_stage==1 and kills>=5: mission_stage=2
	if mission_stage==4 and kind==Zombie.Kind.WAECHTER: mission_stage=5
	_update_hud()

func _update_position_stage()->void:
	var z:=player.position.z; var old:=mission_stage
	if mission_stage==0 and z>7: mission_stage=1
	elif mission_stage==3 and z>70: mission_stage=4
	if old!=mission_stage:_update_hud()

func toggle_settings()->void:
	paused=not paused; settings_panel.visible=paused; joystick.visible=not paused

func _update_hud()->void:
	if not mobile_hud:return
	mobile_hud.set_status(health,ammo,reserve); var text:String=objectives[min(mission_stage,objectives.size()-1)]; if mission_stage==1:text="Sichere den Weg zur Apotheke (%d/5)"%min(kills,5); mobile_hud.set_objective(text)

func _block(name:String,position:Vector3,size:Vector3,color:Color)->void:
	var body:=StaticBody3D.new(); body.name=name; body.position=position; var mesh:=MeshInstance3D.new(); var box:=BoxMesh.new(); box.size=size; mesh.mesh=box; mesh.material_override=_material(color,0.9); body.add_child(mesh); var collision:=CollisionShape3D.new(); var shape:=BoxShape3D.new(); shape.size=size; collision.shape=shape; body.add_child(collision); add_child(body)

func _material(color:Color,roughness:float)->StandardMaterial3D:
	var material:=StandardMaterial3D.new(); material.albedo_color=color; material.roughness=roughness; return material
