extends Node3D

var car: Node3D
var camera: Camera3D
var speed := 0.0
var steer := 0.0
var accelerate := false
var brake := false
var left := false
var right := false
var speed_label: Label

func _ready() -> void:
    _build_world()
    _build_ui()

func _box(parent: Node3D, name: String, position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = name
    var mesh := BoxMesh.new()
    mesh.size = size
    node.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    node.material_override = material
    node.position = position
    parent.add_child(node)
    return node

func _build_world() -> void:
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-45, -25, 0)
    light.light_energy = 1.3
    add_child(light)
    _box(self, "Desert ground", Vector3(0, -0.3, 0), Vector3(1200, 0.5, 1200), Color(0.82, 0.72, 0.53))
    _box(self, "Main asphalt", Vector3(0, 0.02, 0), Vector3(18, 0.08, 1200), Color(0.16, 0.18, 0.21))
    _box(self, "Cross road", Vector3(0, 0.025, -100), Vector3(700, 0.08, 18), Color(0.16, 0.18, 0.21))
    for i in range(-55, 56):
        _box(self, "Road marking", Vector3(0, 0.09, i * 10), Vector3(0.18, 0.02, 4), Color.WHITE)
    for i in range(-24, 25):
        if abs(i) < 2:
            continue
        for side in [-1, 1]:
            var x: float = side * (28 + (abs(i) % 4) * 7)
            var h: float = 12 + (abs(i * 7) % 12) * 4
            _box(self, "City building", Vector3(x, h / 2.0, i * 22), Vector3(12, h, 14), Color(0.73, 0.78, 0.81))
    car = Node3D.new()
    car.name = "PlayerCar"
    add_child(car)
    _box(car, "Car body", Vector3(0, 0.95, 0), Vector3(2.2, 0.7, 4.3), Color(0.85, 0.1, 0.09))
    _box(car, "Cabin", Vector3(0, 1.55, -0.3), Vector3(1.8, 0.65, 2.1), Color(0.15, 0.26, 0.35))
    for x in [-1.12, 1.12]:
        for z in [-1.3, 1.3]:
            _box(car, "Wheel", Vector3(x, 0.5, z), Vector3(0.3, 0.75, 0.8), Color(0.06, 0.06, 0.07))
    camera = Camera3D.new()
    camera.current = true
    camera.position = Vector3(0, 5, 10)
    add_child(camera)
    camera.look_at(Vector3(0, 1, 0))

func _build_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var ui := Control.new()
    ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(ui)
    speed_label = Label.new()
    speed_label.position = Vector2(20, 18)
    speed_label.add_theme_font_size_override("font_size", 26)
    ui.add_child(speed_label)
    _button(ui, "◀", Vector2(0.03, 0.77), Vector2(100, 95), "left")
    _button(ui, "▶", Vector2(0.19, 0.77), Vector2(100, 95), "right")
    _button(ui, "BRAKE", Vector2(0.68, 0.77), Vector2(115, 95), "brake")
    _button(ui, "GAS", Vector2(0.85, 0.77), Vector2(100, 95), "accelerate")

func _button(ui: Control, title: String, anchor: Vector2, dimensions: Vector2, action: String) -> void:
    var b := Button.new()
    b.text = title
    b.position = Vector2.ZERO
    b.size = dimensions
    b.anchor_left = anchor.x
    b.anchor_top = anchor.y
    b.anchor_right = anchor.x
    b.anchor_bottom = anchor.y
    b.offset_left = 0
    b.offset_top = 0
    b.offset_right = dimensions.x
    b.offset_bottom = dimensions.y
    ui.add_child(b)
    b.button_down.connect(func(): set(action, true))
    b.button_up.connect(func(): set(action, false))

func _physics_process(delta: float) -> void:
    var throttle: float = 1.0 if (accelerate or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)) else 0.0
    var braking: float = 1.0 if (brake or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) else 0.0
    var steering: float = (1.0 if (right or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) else 0.0) - (1.0 if (left or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)) else 0.0)
    speed = move_toward(speed, throttle * 28.0 - braking * 9.0, delta * (12.0 if throttle or braking else 6.0))
    car.rotate_y(-steering * delta * speed * 0.025)
    car.position += -car.global_transform.basis.z * speed * delta
    var desired := car.global_position + car.global_transform.basis * Vector3(0, 5.5, 11)
    camera.global_position = camera.global_position.lerp(desired, min(delta * 5.0, 1.0))
    camera.look_at(car.global_position + Vector3.UP * 1.3)
    speed_label.text = "ABU DHABI CITY DRIVE    %d km/h" % int(abs(speed) * 3.6)
