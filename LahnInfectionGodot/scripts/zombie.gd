extends CharacterBody3D

enum Kind { SCHLURFER, RENNER, WAECHTER }
var kind:Kind=Kind.SCHLURFER
var target:CharacterBody3D
var game:Node
var health:=100
var speed:=1.5
var damage:=10
var attack_wait:=0.0
var visual_root:Node3D
var left_arm:MeshInstance3D
var right_arm:MeshInstance3D
var left_leg:MeshInstance3D
var right_leg:MeshInstance3D
var walk_time:=0.0

func setup(new_kind:Kind,player:CharacterBody3D,owner_game:Node)->void:
	kind=new_kind; target=player; game=owner_game
	match kind:
		Kind.RENNER: health=70; speed=4.6; damage=16
		Kind.WAECHTER: health=260; speed=2.0; damage=25
		_: health=100; speed=1.45; damage=10
	_build_body()

func _build_body()->void:
	visual_root=Node3D.new(); visual_root.name="InfectedVisual"; add_child(visual_root)
	var skin:=Color("747862"); var cloth:=Color("454a42") if kind==Kind.SCHLURFER else Color("71332e") if kind==Kind.RENNER else Color("26344a"); var dark:=Color("202522"); var s:=1.18 if kind==Kind.WAECHTER else 1.0
	_capsule("Torso",Vector3(0,0.28,0),0.36*s,0.95*s,cloth,Vector3(1.0,1.0,0.72))
	_capsule("Neck",Vector3(0,0.86*s,0),0.14*s,0.34*s,skin)
	_sphere("Head",Vector3(0,1.12*s,-0.04),Vector3(0.42,0.50,0.40)*s,skin)
	# sunken eyes and blood-dark mouth make the silhouette readable on mobile
	_sphere("EyeL",Vector3(-0.13*s,1.20*s,-0.36*s),Vector3(0.055,0.04,0.025)*s,Color("17120f"))
	_sphere("EyeR",Vector3(0.13*s,1.20*s,-0.36*s),Vector3(0.055,0.04,0.025)*s,Color("17120f"))
	_capsule("Jaw",Vector3(0,1.01*s,-0.30*s),0.12*s,0.28*s,Color("5b3029"),Vector3(1.35,0.45,0.55))
	left_arm=_capsule("ArmL",Vector3(-0.48*s,0.24*s,-0.06),0.12*s,0.92*s,skin); right_arm=_capsule("ArmR",Vector3(0.48*s,0.24*s,-0.06),0.12*s,0.92*s,skin)
	left_leg=_capsule("LegL",Vector3(-0.19*s,-0.78*s,0),0.14*s,1.12*s,dark); right_leg=_capsule("LegR",Vector3(0.19*s,-0.78*s,0),0.14*s,1.12*s,dark)
	left_arm.rotation_degrees.x=-30; right_arm.rotation_degrees.x=-38
	if kind==Kind.WAECHTER:
		_capsule("Vest",Vector3(0,0.35,-0.04),0.42,0.82,Color("101923"),Vector3(1.0,1.0,0.65)); _sphere("Helmet",Vector3(0,1.38,0),Vector3(0.48,0.25,0.45),Color("111820")); _box("Visor",Vector3(0,1.25,-0.39),Vector3(0.48,0.16,0.04),Color(0.08,0.12,0.14,0.82))
	var collision:=CollisionShape3D.new(); var shape:=CapsuleShape3D.new(); shape.radius=0.48 if kind!=Kind.WAECHTER else 0.65; shape.height=1.85 if kind!=Kind.WAECHTER else 2.15; collision.shape=shape; add_child(collision)

func _capsule(n:String,p:Vector3,r:float,h:float,c:Color,sc:=Vector3.ONE)->MeshInstance3D:
	var m:=MeshInstance3D.new(); m.name=n; var mesh:=CapsuleMesh.new(); mesh.radius=r; mesh.height=max(h,r*2.05); m.mesh=mesh; m.position=p; m.scale=sc; m.material_override=_material(c,0.86); visual_root.add_child(m); return m
func _sphere(n:String,p:Vector3,sc:Vector3,c:Color)->MeshInstance3D:
	var m:=MeshInstance3D.new(); m.name=n; var mesh:=SphereMesh.new(); mesh.radius=0.5; mesh.height=1.0; m.mesh=mesh; m.position=p; m.scale=sc; m.material_override=_material(c,0.9); visual_root.add_child(m); return m
func _box(n:String,p:Vector3,sc:Vector3,c:Color)->MeshInstance3D:
	var m:=MeshInstance3D.new(); m.name=n; var mesh:=BoxMesh.new(); mesh.size=sc; m.mesh=mesh; m.position=p; m.material_override=_material(c,0.35); visual_root.add_child(m); return m

func _physics_process(delta:float)->void:
	if not is_instance_valid(target) or game.paused: velocity=Vector3.ZERO; return
	attack_wait-=delta; var d:=target.global_position-global_position; d.y=0
	if d.length_squared()>1024: velocity=Vector3.ZERO; return
	if d.length()>1.55:
		velocity=d.normalized()*speed; look_at(global_position+d,Vector3.UP); move_and_slide(); _animate_walk(delta)
	elif attack_wait<=0:
		attack_wait=1.15; _attack_motion(); game.hurt_player(damage)

func _animate_walk(delta:float)->void:
	walk_time+=delta*(9.0 if kind==Kind.RENNER else 4.5); var swing:=sin(walk_time)*28.0
	visual_root.position.y=sin(walk_time*2.0)*0.035; visual_root.rotation_degrees.z=sin(walk_time)*3.0
	left_arm.rotation_degrees.x=-30+swing; right_arm.rotation_degrees.x=-34-swing
	left_leg.rotation_degrees.x=-swing*0.55; right_leg.rotation_degrees.x=swing*0.55
func _attack_motion()->void:
	var t:=create_tween(); t.tween_property(visual_root,"rotation_degrees:x",-18.0,0.10); t.tween_property(visual_root,"rotation_degrees:x",0.0,0.18)
func hit(amount:int)->void:
	health-=amount; game.play_sound("hit"); var t:=create_tween(); t.tween_property(visual_root,"scale",Vector3(1.08,0.93,1.08),0.05); t.tween_property(visual_root,"scale",Vector3.ONE,0.1)
	if health<=0: game.zombie_defeated(self,kind); queue_free()
func _material(c:Color,r:float)->StandardMaterial3D:
	var m:=StandardMaterial3D.new(); m.albedo_color=c; m.roughness=r; return m
