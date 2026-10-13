extends Node3D
var car: Node3D
var cam: Camera3D
var velocity := 0.0
var gas := false
var braking := false
var steer := 0.0
func _ready():
 var ground = MeshInstance3D.new()
 var plane = BoxMesh.new()
 plane.size = Vector3(600,0.2,600)
 ground.mesh = plane
 add_child(ground)
 for i in range(-3,4):
  add_box(Vector3(i*75,0.1,0),Vector3(16,0.1,600),Color.DARK_GRAY)
  add_box(Vector3(0,0.1,i*75),Vector3(600,0.1,16),Color.DARK_GRAY)
  for j in range(-3,4):
   if i != 0 and j != 0:
    add_box(Vector3(i*75+27,15,j*75+27),Vector3(22,30,22),Color.SLATE_GRAY)
 car = Node3D.new()
 car.position.y = 1
 add_child(car)
 add_box(Vector3.ZERO,Vector3(2,1,4),Color.RED,car)
 cam = Camera3D.new()
 cam.current = true
 add_child(cam)
 var light = DirectionalLight3D.new()
 light.rotation_degrees = Vector3(-50,30,0)
 add_child(light)
 var ui = CanvasLayer.new()
 add_child(ui)
 make_button(ui,"LEFT",Vector2(20,480),-1)
 make_button(ui,"RIGHT",Vector2(130,480),1)
 make_button(ui,"BRAKE",Vector2(420,480),2)
 make_button(ui,"GAS",Vector2(530,480),3)
func add_box(pos:Vector3,size:Vector3,color:Color,parent:Node3D=self):
 var mesh = MeshInstance3D.new()
 var box = BoxMesh.new()
 box.size = size
 mesh.mesh = box
 var mat = StandardMaterial3D.new()
 mat.albedo_color = color
 mesh.material_override = mat
 mesh.position = pos
 parent.add_child(mesh)
func make_button(ui:CanvasLayer,title:String,pos:Vector2,kind:int):
 var b = Button.new()
 b.text = title
 b.position = pos
 b.size = Vector2(100,70)
 ui.add_child(b)
 b.button_down.connect(func(): control(kind,true))
 b.button_up.connect(func(): control(kind,false))
func control(kind:int,down:bool):
 if kind == -1: steer = -1.0 if down else 0.0
 if kind == 1: steer = 1.0 if down else 0.0
 if kind == 2: braking = down
 if kind == 3: gas = down
func _process(delta):
 var acceleration = gas or Input.is_key_pressed(KEY_W)
 var deceleration = braking or Input.is_key_pressed(KEY_S)
 velocity = move_toward(velocity,30.0 if acceleration else (-8.0 if deceleration else 0.0),delta*12)
 var direction = steer
 if Input.is_key_pressed(KEY_A): direction = -1
 if Input.is_key_pressed(KEY_D): direction = 1
 car.rotate_y(-direction*velocity*delta*0.045)
 car.position -= car.transform.basis.z*velocity*delta
 cam.position = cam.position.lerp(car.position+car.transform.basis*Vector3(0,5,11),min(1.0,delta*6))
 cam.look_at(car.position)
