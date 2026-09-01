extends Node3D

var player: CharacterBody3D
var camera: Camera3D
var pivot: Node3D
var hud: Label
var mission: Label
var menu: Control
var settings: Control
var move_input := Vector2.ZERO
var yaw := 0.0
var pitch := -0.18
var sensitivity := 0.004
var hp := 100
var ammo := 12
var reserve := 60
var score := 0
var kills := 0
var started := false
var zombies: Array[CharacterBody3D] = []
var story_panel: ColorRect
var story_text: Label
var story_step := 0

func _ready() -> void:
	build_world(); build_player(); build_ui(); load_settings()
	for i in range(9): spawn_zombie(i % 3, Vector3(-7.0 + (i%5)*3.0, 0, -10.0-i*4.0))

func material(c:Color)->StandardMaterial3D:
	var m:=StandardMaterial3D.new(); m.albedo_color=c; m.roughness=.94
	m.shading_mode=BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.diffuse_mode=BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode=BaseMaterial3D.SPECULAR_TOON
	return m

func box(pos:Vector3,size:Vector3,c:Color,collision:=true)->MeshInstance3D:
	var n:=MeshInstance3D.new(); var mesh:=BoxMesh.new(); mesh.size=size; mesh.material=material(c); n.mesh=mesh; n.position=pos; add_child(n)
	if collision:
		var body:=StaticBody3D.new(); var shape:=CollisionShape3D.new(); var form:=BoxShape3D.new(); form.size=size; shape.shape=form; body.add_child(shape); n.add_child(body)
	return n

func build_world()->void:
	var we:=WorldEnvironment.new(); var e:=Environment.new(); e.background_mode=Environment.BG_COLOR; e.background_color=Color("05070b"); e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color=Color("667785"); e.ambient_light_energy=.42; e.fog_enabled=true; e.fog_light_color=Color("172028"); e.fog_density=.018; we.environment=e; add_child(we)
	var moon:=DirectionalLight3D.new(); moon.rotation_degrees=Vector3(-58,-30,0); moon.light_color=Color("a1b8ce"); moon.shadow_enabled=true; add_child(moon)
	box(Vector3(0,-.5,-14),Vector3(44,1,95),Color("262829"))
	box(Vector3(-6,.08,-14),Vector3(4,.16,95),Color("74706a"),false); box(Vector3(6,.08,-14),Vector3(4,.16,95),Color("74706a"),false)
	for side in [-1,1]:
		for z in range(-50,27,12):
			var h:=7.0+float(abs(z)%6); box(Vector3(side*13,h/2,z),Vector3(10,h,10),Color("343638"))
	for z in range(-48,25,9): box(Vector3(-2.7,.11,z),Vector3(.14,.03,3.5),Color("ddd5bd"),false)
	# Deutsche Bushaltestelle und Apotheke als erste Missionsziele.
	box(Vector3(5,1.5,8),Vector3(.25,3,4.5),Color("405967")); box(Vector3(5,3.1,8),Vector3(2.8,.3,4.5),Color("577484"))
	box(Vector3(-11,2,-28),Vector3(.3,1.2,2.8),Color("a8d7b0"),false)

func build_player()->void:
	player=CharacterBody3D.new(); player.position=Vector3(0,1,18); add_child(player)
	var col:=CollisionShape3D.new(); var cap:=CapsuleShape3D.new(); cap.height=1.8; cap.radius=.42; col.shape=cap; player.add_child(col)
	var body:=MeshInstance3D.new(); var mesh:=CapsuleMesh.new(); mesh.height=1.8; mesh.radius=.42; mesh.material=material(Color("25384a")); body.mesh=mesh; player.add_child(body)
	pivot=Node3D.new(); pivot.position=Vector3(0,1.45,0); player.add_child(pivot)
	var arm:=SpringArm3D.new(); arm.spring_length=4.3; pivot.add_child(arm); camera=Camera3D.new(); camera.current=true; arm.add_child(camera)

func spawn_zombie(kind:int,pos:Vector3)->void:
	var z:=CharacterBody3D.new(); z.position=pos; z.set_meta("hp",[100,65,240][kind]); z.set_meta("speed",[1.5,3.0,.8][kind]); z.set_meta("kind",kind); add_child(z); zombies.append(z)
	var col:=CollisionShape3D.new(); var cap:=CapsuleShape3D.new(); cap.height=[1.8,1.65,2.2][kind]; cap.radius=[.38,.33,.62][kind]; col.shape=cap; z.add_child(col)
	var body:=MeshInstance3D.new(); var mesh:=CapsuleMesh.new(); mesh.height=cap.height; mesh.radius=cap.radius; mesh.material=material([Color("43503b"),Color("65443b"),Color("303b34")][kind]); body.mesh=mesh; z.add_child(body)

func build_ui()->void:
	var layer:=CanvasLayer.new(); add_child(layer); hud=Label.new(); hud.position=Vector2(22,18); hud.add_theme_font_size_override("font_size",22); layer.add_child(hud)
	mission=Label.new(); mission.position=Vector2(365,20); mission.size=Vector2(550,45); mission.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; mission.add_theme_font_size_override("font_size",20); layer.add_child(mission)
	var controls:=Control.new(); controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); layer.add_child(controls)
	hold_button(controls,"▲",Vector2(90,530),Vector2(0,-1)); hold_button(controls,"▼",Vector2(90,640),Vector2(0,1)); hold_button(controls,"◀",Vector2(12,605),Vector2(-1,0)); hold_button(controls,"▶",Vector2(168,605),Vector2(1,0))
	var fire:=Button.new(); fire.text="FEUER"; fire.position=Vector2(1090,570); fire.size=Vector2(150,110); fire.pressed.connect(shoot); controls.add_child(fire)
	var reload:=Button.new(); reload.text="LADEN"; reload.position=Vector2(955,625); reload.size=Vector2(120,70); reload.pressed.connect(reload_weapon); controls.add_child(reload)
	var gear:=Button.new(); gear.text="⚙"; gear.position=Vector2(1190,18); gear.size=Vector2(65,55); gear.pressed.connect(toggle_settings); controls.add_child(gear)
	menu=ColorRect.new(); menu.color=Color(0,0,0,.94); menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); layer.add_child(menu)
	var title:=Label.new(); title.text="ZOMBIE CITY"; title.position=Vector2(0,120); title.size=Vector2(1280,90); title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size",68); menu.add_child(title)
	var warning:=Label.new(); warning.text="AB 18 • STARKE GEWALTDARSTELLUNG"; warning.position=Vector2(0,230); warning.size=Vector2(1280,45); warning.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; warning.add_theme_color_override("font_color",Color("c62929")); warning.add_theme_font_size_override("font_size",22); menu.add_child(warning)
	var play:=Button.new(); play.text="NEUES SPIEL"; play.position=Vector2(490,365); play.size=Vector2(300,90); play.add_theme_font_size_override("font_size",30); play.pressed.connect(func():started=true;menu.visible=false); menu.add_child(play)
	settings=ColorRect.new(); settings.color=Color(.03,.04,.05,.97); settings.position=Vector2(340,120); settings.size=Vector2(600,480); settings.visible=false; layer.add_child(settings); build_settings()
	story_panel=ColorRect.new(); story_panel.color=Color(0,0,0,.9); story_panel.position=Vector2(110,500); story_panel.size=Vector2(1060,170); story_panel.visible=false; layer.add_child(story_panel)
	story_text=Label.new(); story_text.position=Vector2(28,20); story_text.size=Vector2(1000,85); story_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; story_text.add_theme_font_size_override("font_size",23); story_panel.add_child(story_text)
	var next:=Button.new(); next.text="WEITER"; next.position=Vector2(820,105); next.size=Vector2(200,48); next.pressed.connect(next_story); story_panel.add_child(next)

func hold_button(parent:Control,text:String,pos:Vector2,dir:Vector2)->void:
	var b:=Button.new(); b.text=text; b.position=pos; b.size=Vector2(78,70); b.add_theme_font_size_override("font_size",28); b.button_down.connect(func():move_input+=dir); b.button_up.connect(func():move_input-=dir); parent.add_child(b)

func build_settings()->void:
	var head:=Label.new(); head.text="EINSTELLUNGEN"; head.position=Vector2(0,25); head.size=Vector2(600,50); head.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; head.add_theme_font_size_override("font_size",30); settings.add_child(head)
	var label:=Label.new(); label.text="Kamera-Empfindlichkeit"; label.position=Vector2(140,110); settings.add_child(label)
	var slider:=HSlider.new(); slider.min_value=1; slider.max_value=10; slider.value=4; slider.position=Vector2(140,145); slider.size=Vector2(320,40); slider.value_changed.connect(func(v):sensitivity=v/1000.0;save_settings()); settings.add_child(slider)
	var blood:=CheckButton.new(); blood.text="Blutdarstellung"; blood.button_pressed=true; blood.position=Vector2(140,215); settings.add_child(blood)
	var aim:=CheckButton.new(); aim.text="Zielhilfe"; aim.button_pressed=true; aim.position=Vector2(140,270); settings.add_child(aim)
	var close:=Button.new(); close.text="ZURÜCK"; close.position=Vector2(200,370); close.size=Vector2(200,65); close.pressed.connect(toggle_settings); settings.add_child(close)

func toggle_settings()->void: settings.visible=!settings.visible
func save_settings()->void:
	var cfg:=ConfigFile.new(); cfg.set_value("controls","sensitivity",sensitivity); cfg.save("user://settings.cfg")
func load_settings()->void:
	var cfg:=ConfigFile.new()
	if cfg.load("user://settings.cfg")==OK: sensitivity=float(cfg.get_value("controls","sensitivity",.004))

func _unhandled_input(event:InputEvent)->void:
	if event is InputEventScreenDrag and event.position.x>400 and not settings.visible:
		yaw-=event.relative.x*sensitivity; pitch=clamp(pitch-event.relative.y*sensitivity,-.8,.35)

func shoot()->void:
	if not started or settings.visible:return
	if ammo<=0:reload_weapon();return
	ammo-=1; var q:=PhysicsRayQueryParameters3D.create(camera.global_position,camera.global_position-camera.global_basis.z*80); q.exclude=[player]
	var hit:=get_world_3d().direct_space_state.intersect_ray(q)
	if hit and hit.collider in zombies:
		var z:CharacterBody3D=hit.collider; z.set_meta("hp",int(z.get_meta("hp"))-50)
		if int(z.get_meta("hp"))<=0:
			zombies.erase(z); z.queue_free(); score+=100; kills+=1
			if kills==5: begin_story()

func reload_weapon()->void:
	var amount:=min(12-ammo,reserve); ammo+=amount; reserve-=amount

func begin_story()->void:
	story_step=0; story_panel.visible=true; next_story()

func next_story()->void:
	var lines=[
		"Mara (Funk): Die Apotheke ist nicht sicher. Die Bundesstraße wurde abgeriegelt.",
		"Jonas: Mara? Wo bist du?",
		"Mara (Funk): Krankenhaus West. Aber komm nicht über den Bahnhof.",
		"NEUE MISSION: Erreiche das Krankenhaus und finde Mara."
	]
	if story_step<lines.size(): story_text.text=lines[story_step]; story_step+=1
	else: story_panel.visible=false

func _physics_process(delta:float)->void:
	if not started or settings.visible:return
	pivot.rotation=Vector3(pitch,yaw,0); player.rotation.y=yaw
	var dir:=Vector3(move_input.x,0,move_input.y).normalized().rotated(Vector3.UP,yaw); player.velocity=Vector3(dir.x*4.5,-3,dir.z*4.5); player.move_and_slide()
	for z in zombies:
		if not is_instance_valid(z):continue
		var d:=player.global_position-z.global_position; d.y=0
		if d.length()<24: z.velocity=d.normalized()*float(z.get_meta("speed")); z.look_at(player.global_position,Vector3.UP); z.move_and_slide();
		if d.length()<1.25:hp=max(0,hp-int(18*delta))
	hud.text="LEBEN %d   MUNITION %d/%d   PUNKTE %d"%[hp,ammo,reserve,score]
	mission.text="MISSION: Sichere den Weg zur Apotheke (%d/5)"%min(kills,5) if kills<5 else "MISSION ERFÜLLT: Weg zur Apotheke gesichert"
