extends Node3D

var car: Node3D
var cam: Camera3D
var speed := 0.0
var steer := 0.0
var gas := false
var brake := false
var left := false
var right := false
var speed_text: Label
var mission_text: Label
var nav_text: Label
var traffic: Array[Node3D] = []
var mission := 0
var camera_mode := 0
var goals := [Vector3(-300, 0, -300), Vector3(300, 0, -300), Vector3(300, 0, 300), Vector3(-300, 0, 300)]
var names := ["Corniche district", "Capital towers", "Desert boulevard", "Palm district"]
var goal_beacon: MeshInstance3D
var map_dot: ColorRect
var map_goal: ColorRect

func _box(parent: Node3D, name: String, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
    var m := MeshInstance3D.new()
    m.name = name
    var mesh := BoxMesh.new()
    mesh.size = size
    m.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    m.material_override = mat
    m.position = pos
    parent.add_child(m)
    return m

func _palm(x: float, z: float) -> void:
    _box(self, "Palm trunk", Vector3(x, 3.0, z), Vector3(0.5, 6.0, 0.5), Color(0.49, 0.31, 0.17))
    for k in range(4):
        var frond := _box(self, "Palm leaves", Vector3(x, 6.2, z), Vector3(0.7, 0.3, 7.0), Color(0.10, 0.39, 0.18))
        frond.rotation.y = float(k) * PI / 4.0

func _make_car(paint: Color) -> Node3D:
    var v := Node3D.new()
    add_child(v)
    _box(v, "Body", Vector3(0, 0.95, 0), Vector3(2.2, 0.7, 4.4), paint)
    _box(v, "Cabin", Vector3(0, 1.55, -0.3), Vector3(1.75, 0.62, 2.3), paint.darkened(0.2))
    _box(v, "Front glass", Vector3(0, 1.6, -1.48), Vector3(1.55, 0.42, 0.12), Color(0.16, 0.33, 0.42))
    _box(v, "Rear glass", Vector3(0, 1.6, 0.88), Vector3(1.55, 0.42, 0.12), Color(0.16, 0.33, 0.42))
    for x in [-1.12, 1.12]:
        for z in [-1.35, 1.35]:
            _box(v, "Wheel", Vector3(x, 0.47, z), Vector3(0.3, 0.9, 0.85), Color(0.07, 0.07, 0.08))
        _box(v, "Headlight", Vector3(x * 0.7, 0.95, -2.24), Vector3(0.45, 0.22, 0.08), Color(1.0, 0.96, 0.75))
        _box(v, "Taillight", Vector3(x * 0.7, 0.95, 2.24), Vector3(0.45, 0.22, 0.08), Color(0.9, 0.1, 0.1))
    return v

func _ready() -> void:
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-50, -25, 0)
    light.light_energy = 1.4
    add_child(light)
    _box(self, "Sand", Vector3(0, -0.4, 0), Vector3(1200, 0.6, 1200), Color(0.84, 0.75, 0.55))
    _box(self, "Waterfront", Vector3(-520, -0.1, 0), Vector3(130, 0.2, 1100), Color(0.08, 0.52, 0.68))
    for i in range(-4, 5):
        var p := float(i) * 100.0
        _box(self, "North south road", Vector3(p, 0.02, 0), Vector3(20, 0.09, 1000), Color(0.15, 0.17, 0.19))
        _box(self, "East west road", Vector3(0, 0.03, p), Vector3(1000, 0.09, 20), Color(0.15, 0.17, 0.19))
        for j in range(-47, 48):
            var t := float(j) * 10.0
            if abs(fmod(abs(t), 100.0)) < 15.0:
                continue
            _box(self, "Center line", Vector3(p, 0.09, t), Vector3(0.18, 0.02, 4), Color(0.95, 0.9, 0.75))
            _box(self, "Cross center line", Vector3(t, 0.10, p), Vector3(4, 0.02, 0.18), Color(0.95, 0.9, 0.75))
    for x in range(-4, 4):
        for z in range(-4, 4):
            var xx := float(x) * 100.0 + 50.0
            var zz := float(z) * 100.0 + 50.0
            var n := abs(x * 17 + z * 11)
            var h := float(16 + (n * 7) % 55)
            _box(self, "City tower", Vector3(xx - 16, h * 0.5, zz - 15), Vector3(18, h, 20), Color(0.62 + float(n % 3) * 0.08, 0.72, 0.78))
            _box(self, "Glass windows", Vector3(xx - 16, h * 0.5, zz - 4.9), Vector3(13, h * 0.8, 0.18), Color(0.24, 0.45, 0.56))
            _palm(xx + 20, zz + 20)
    car = _make_car(Color(0.86, 0.11, 0.08))
    car.position = Vector3(0, 0, 50)
    for i in range(14):
        var v := _make_car([Color(0.94, 0.94, 0.92), Color(0.16, 0.28, 0.43), Color(0.60, 0.64, 0.68)][i % 3])
        v.position = Vector3(float((i % 7) - 3) * 100.0 + (5.0 if i % 2 == 0 else -5.0), 0, float(i * 53 % 700) - 350.0)
        v.rotation.y = PI if i % 2 == 0 else 0.0
        traffic.append(v)
    goal_beacon = _box(self, "Green mission marker", goals[0] + Vector3(0, 2, 0), Vector3(5, 4, 5), Color(0.1, 0.94, 0.36))
    cam = Camera3D.new()
    cam.current = true
    cam.fov = 72.0
    add_child(cam)
    cam.position = Vector3(0, 6, 63)
    _make_ui()

func _label(ui: Control, y: float, size: int) -> Label:
    var l := Label.new()
    l.position = Vector2(16, y)
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", Color.WHITE)
    l.add_theme_color_override("font_shadow_color", Color.BLACK)
    l.add_theme_constant_override("shadow_offset_x", 2)
    l.add_theme_constant_override("shadow_offset_y", 2)
    ui.add_child(l)
    return l

func _button(ui: Control, label: String, x: float, y: float, width: float, action: String) -> void:
    var b := Button.new()
    b.text = label
    b.anchor_left = x
    b.anchor_right = x
    b.anchor_top = y
    b.anchor_bottom = y
    b.offset_right = width
    b.offset_bottom = 86.0 if action != "cam" else 52.0
    b.add_theme_font_size_override("font_size", 21)
    ui.add_child(b)
    if action == "cam":
        b.pressed.connect(func(): camera_mode = (camera_mode + 1) % 3)
    else:
        b.button_down.connect(func(): set(action, true))
        b.button_up.connect(func(): set(action, false))

func _make_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var ui := Control.new()
    ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(ui)
    speed_text = _label(ui, 12, 25)
    mission_text = _label(ui, 50, 19)
    nav_text = _label(ui, 79, 18)
    _button(ui, "LEFT", 0.02, 0.77, 112, "left")
    _button(ui, "RIGHT", 0.20, 0.77, 112, "right")
    _button(ui, "BRAKE", 0.67, 0.77, 112, "brake")
    _button(ui, "GAS", 0.85, 0.77, 100, "gas")
    _button(ui, "CAMERA", 0.83, 0.04, 112, "cam")
    var minimap := Control.new()
    minimap.anchor_left = 1.0
    minimap.anchor_right = 1.0
    minimap.offset_left = -177
    minimap.offset_right = -12
    minimap.offset_top = 110
    minimap.offset_bottom = 275
    ui.add_child(minimap)
    var bg := ColorRect.new()
    bg.size = Vector2(165, 165)
    bg.color = Color(0.08, 0.16, 0.19, 0.9)
    minimap.add_child(bg)
    for i in range(9):
        var v := ColorRect.new()
        v.position = Vector2(2 + i * 20, 0)
        v.size = Vector2(2, 165)
        v.color = Color(0.46, 0.48, 0.49)
        minimap.add_child(v)
        var h := ColorRect.new()
        h.position = Vector2(0, 2 + i * 20)
        h.size = Vector2(165, 2)
        h.color = Color(0.46, 0.48, 0.49)
        minimap.add_child(h)
    map_dot = ColorRect.new()
    map_dot.size = Vector2(9, 9)
    map_dot.color = Color(1, 0.2, 0.1)
    minimap.add_child(map_dot)
    map_goal = ColorRect.new()
    map_goal.size = Vector2(9, 9)
    map_goal.color = Color(0.1, 1, 0.2)
    minimap.add_child(map_goal)

func _physics_process(delta: float) -> void:
    var throttle := gas or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
    var stopping := brake or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
    var direction := (1.0 if (right or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) else 0.0) - (1.0 if (left or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)) else 0.0)
    steer = move_toward(steer, direction, delta * 4.0)
    var target := 0.0
    if throttle:
        target = 29.0
    if stopping:
        target = 0.0
    speed = move_toward(speed, target, delta * (20.0 if stopping else 10.0 if throttle else 5.0))
    car.rotate_y(-steer * delta * minf(speed / 10.0, 1.0) * 1.4)
    car.position += -car.transform.basis.z * speed * delta
    car.position.x = clampf(car.position.x, -480.0, 480.0)
    car.position.z = clampf(car.position.z, -480.0, 480.0)
    for i in range(traffic.size()):
        var v := traffic[i]
        v.position += -v.transform.basis.z * (9.0 + float(i % 4) * 2.0) * delta
        if v.position.z > 470:
            v.position.z = -470
        if v.position.z < -470:
            v.position.z = 470
        if v.position.distance_to(car.position) < 4.0:
            speed = move_toward(speed, 0.0, delta * 30.0)
    var offset := Vector3(0, 5.5, 11)
    if camera_mode == 1:
        offset = Vector3(0, 2.2, -0.8)
    if camera_mode == 2:
        offset = Vector3(0, 16, 17)
    var desired: Vector3 = car.global_position + car.global_transform.basis * offset
    cam.global_position = cam.global_position.lerp(desired, minf(delta * 5.0, 1.0))
    cam.look_at(car.global_position + car.global_transform.basis * Vector3(0, 1, -5))
    var goal: Vector3 = goals[mission % goals.size()]
    var distance := Vector2(car.position.x - goal.x, car.position.z - goal.z).length()
    if distance < 17.0:
        mission += 1
        goal = goals[mission % goals.size()]
        goal_beacon.position = goal + Vector3(0, 2, 0)
    speed_text.text = "ABU DHABI DRIVE  |  %d km/h" % int(speed * 3.6)
    mission_text.text = "Mission %d: %s" % [mission + 1, names[mission % names.size()]]
    nav_text.text = "GPS: %d m to green marker" % int(distance)
    map_dot.position = Vector2(clampf(82 + car.position.x * 0.18, 0, 155), clampf(82 + car.position.z * 0.18, 0, 155))
    map_goal.position = Vector2(clampf(82 + goal.x * 0.18, 0, 155), clampf(82 + goal.z * 0.18, 0, 155))
