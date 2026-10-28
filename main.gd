extends Node3D

# REAL CHP — BATTLE 0.2
# Playable prototype designed for Android/Godot.
# Original assets/mechanics only; not Free Fire files.

const BASE_HP := 200.0
const BASE_ENERGY := 200.0
const NORMAL_SHIELD_MAX := 70.0

var player: CharacterBody3D
var camera: Camera3D
var yaw := 0.0
var pitch := -0.08
var speed := 6.0
var gravity := 18.0

var character_name := "Kosmos"
var hp := BASE_HP
var energy := BASE_ENERGY
var shield := 0.0
var ability_ready := true
var ability_time := 0.0
var ability_cooldown := 0.0
var shoot_cooldown := 0.0
var kills := 0

var joystick_id := -1
var joystick_origin := Vector2.ZERO
var joystick_pos := Vector2.ZERO
var look_id := -1

var hp_label: Label
var info_label: Label
var ability_button: Button
var character_label: Label

var characters = {
    "Kosmos": {"color": Color(0.22,0.35,0.95), "ability":"HP 250 • Escudo 90 • Dano ↑ • 30s / 120s"},
    "Lucas": {"color": Color(0.25,0.85,0.95), "ability":"Passiva: inimigos próximos ficam lentos após queda"},
    "Cuíca": {"color": Color(0.95,0.65,0.18), "ability":"Precisão +100% • Dano aumenta por kill"},
    "Danilo": {"color": Color(0.25,0.85,0.35), "ability":"Velocidade ↑ • +50 HP"},
    "Marli": {"color": Color(0.75,0.35,0.65), "ability":"Desativa habilidades dos inimigos próximos"}
}

func _ready():
    _build_world()
    _build_player()
    _build_hud()
    _spawn_targets()

func _build_world():
    var env_node := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.04,0.06,0.08)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.8,0.85,1.0)
    env.ambient_light_energy = 1.0
    env_node.environment = env
    add_child(env_node)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55,-25,0)
    sun.light_energy = 1.2
    add_child(sun)

    var floor := StaticBody3D.new()
    floor.name = "BermudaPrototype"
    add_child(floor)
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(70,1,70)
    mesh.mesh = box
    mesh.position.y = -0.5
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.12,0.24,0.14)
    box.material = mat
    floor.add_child(mesh)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(70,1,70)
    collision.shape = shape
    collision.position.y = -0.5
    floor.add_child(collision)

    # Simple original landmarks for the prototype.
    for data in [
        [Vector3(-10,2,-12), Vector3(5,4,5)],
        [Vector3(12,2,-18), Vector3(7,4,4)],
        [Vector3(-18,1,8), Vector3(4,2,7)],
        [Vector3(18,1,10), Vector3(6,2,6)]
    ]:
        _make_building(data[0], data[1])

func _make_building(pos:Vector3, size:Vector3):
    var body := StaticBody3D.new()
    body.position = pos
    add_child(body)
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.25,0.28,0.32)
    box.material = mat
    body.add_child(mesh)
    var col := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    col.shape = shape
    body.add_child(col)

func _build_player():
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(0,1.2,12)
    add_child(player)

    var col := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.height = 1.8
    capsule.radius = 0.35
    col.shape = capsule
    player.add_child(col)

    var mesh := MeshInstance3D.new()
    var body := CapsuleMesh.new()
    body.height = 1.8
    body.radius = 0.35
    mesh.mesh = body
    var mat := StandardMaterial3D.new()
    mat.albedo_color = characters[character_name]["color"]
    body.material = mat
    player.add_child(mesh)

    # Câmera em terceira pessoa: atrás e acima do personagem, estilo battle royale.
    camera = Camera3D.new()
    camera.name = "ThirdPersonCamera"
    camera.position = Vector3(0, 1.55, 4.6)
    camera.rotation.x = -0.16
    camera.current = true
    camera.fov = 75.0
    player.add_child(camera)

func _spawn_targets():
    for i in range(8):
        var angle = float(i) / 8.0 * TAU
        var pos = Vector3(cos(angle)*14.0, 1.0, sin(angle)*14.0)
        _make_target(pos)

func _make_target(pos:Vector3):
    var target := StaticBody3D.new()
    target.position = pos
    target.set_meta("hp", 100.0)
    target.set_meta("target", true)
    add_child(target)

    var mesh := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.height = 2.0
    capsule.radius = 0.45
    mesh.mesh = capsule
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.75,0.12,0.12)
    capsule.material = mat
    target.add_child(mesh)

    var col := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.height = 2.0
    shape.radius = 0.45
    col.shape = shape
    target.add_child(col)

func _build_hud():
    var layer := CanvasLayer.new()
    add_child(layer)

    character_label = Label.new()
    character_label.position = Vector2(22,18)
    character_label.add_theme_font_size_override("font_size",26)
    layer.add_child(character_label)

    hp_label = Label.new()
    hp_label.position = Vector2(22,55)
    hp_label.add_theme_font_size_override("font_size",21)
    layer.add_child(hp_label)

    info_label = Label.new()
    info_label.position = Vector2(22,92)
    info_label.add_theme_font_size_override("font_size",17)
    layer.add_child(info_label)

    var cross := Label.new()
    cross.text = "+"
    cross.position = Vector2(632,342)
    cross.add_theme_font_size_override("font_size",30)
    layer.add_child(cross)

    ability_button = Button.new()
    ability_button.text = "🐉 HABILIDADE"
    ability_button.position = Vector2(1030,590)
    ability_button.size = Vector2(210,70)
    ability_button.add_theme_font_size_override("font_size",20)
    ability_button.pressed.connect(_use_ability)
    layer.add_child(ability_button)

    var hint := Label.new()
    hint.text = "CÂMERA 3ª PESSOA • ESQUERDA: mover • ARRASTE À DIREITA: girar câmera • TOQUE: atirar"
    hint.position = Vector2(22,675)
    hint.add_theme_font_size_override("font_size",15)
    layer.add_child(hint)

func _physics_process(delta):
    shoot_cooldown = max(0.0, shoot_cooldown - delta)
    if ability_time > 0:
        ability_time -= delta
        if ability_time <= 0:
            _end_ability()
    if ability_cooldown > 0:
        ability_cooldown -= delta
        if ability_cooldown <= 0:
            ability_ready = true
    _move(delta)
    _update_hud()

func _move(delta):
    var input := Vector2.ZERO
    if Input.is_key_pressed(KEY_A): input.x -= 1
    if Input.is_key_pressed(KEY_D): input.x += 1
    if Input.is_key_pressed(KEY_W): input.y -= 1
    if Input.is_key_pressed(KEY_S): input.y += 1

    if joystick_id != -1:
        input = (joystick_pos-joystick_origin).limit_length(100.0)/100.0

    var forward := -player.global_transform.basis.z
    var right := player.global_transform.basis.x
    var dir := right*input.x + forward*(-input.y)
    if dir.length() > 1: dir = dir.normalized()

    var current_speed := speed
    if character_name == "Danilo" and ability_time > 0: current_speed = 9.0
    player.velocity.x = dir.x*current_speed
    player.velocity.z = dir.z*current_speed
    if not player.is_on_floor():
        player.velocity.y -= gravity*delta
    else:
        player.velocity.y = 0
    player.move_and_slide()

func _unhandled_input(event):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        _shoot()
    elif event is InputEventScreenTouch:
        if event.pressed:
            if event.position.x < get_viewport().size.x*0.42:
                joystick_id = event.index
                joystick_origin = event.position
                joystick_pos = event.position
            elif event.position.x > 0.80*get_viewport().size.x and event.position.y > 0.75*get_viewport().size.y:
                pass
            else:
                look_id = event.index
                _shoot()
        else:
            if event.index == joystick_id: joystick_id = -1
            if event.index == look_id: look_id = -1
    elif event is InputEventScreenDrag:
        if event.index == joystick_id:
            joystick_pos = event.position
        elif event.index == look_id:
            _look(event.relative)

func _look(relative:Vector2):
    yaw -= relative.x*0.004
    pitch -= relative.y*0.003
    pitch = clamp(pitch,-1.35,1.35)
    player.rotation.y = yaw
    camera.rotation.x = pitch

func _shoot():
    if shoot_cooldown > 0: return
    shoot_cooldown = 0.18
    var origin := camera.global_position
    var end := origin + (-camera.global_transform.basis.z)*100.0
    var query := PhysicsRayQueryParameters3D.create(origin,end)
    query.exclude = [player]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit:
        var obj = hit.get("collider")
        if obj and obj.has_meta("target"):
            var damage := 25.0
            if character_name == "Kosmos" and ability_time > 0: damage = 35.0
            if character_name == "Cuíca" and ability_time > 0: damage = 30.0 + kills*3.0
            var target_hp := float(obj.get_meta("hp")) - damage
            if target_hp <= 0:
                kills += 1
                obj.queue_free()
            else:
                obj.set_meta("hp",target_hp)

func _use_ability():
    if not ability_ready: return
    ability_ready = false
    if character_name == "Kosmos":
        hp = 250
        shield = 90
        ability_time = 30.0
        ability_cooldown = 120.0
    elif character_name == "Danilo":
        hp = min(250.0,hp+50.0)
        ability_time = 30.0
        ability_cooldown = 90.0
    elif character_name == "Cuíca":
        ability_time = 20.0
        ability_cooldown = 90.0
    elif character_name == "Lucas":
        ability_time = 8.0
        ability_cooldown = 60.0
    elif character_name == "Marli":
        ability_time = 15.0
        ability_cooldown = 90.0

func _end_ability():
    if character_name == "Kosmos":
        hp = min(hp,BASE_HP)
        shield = min(shield,NORMAL_SHIELD_MAX)
    elif character_name == "Danilo":
        hp = min(hp,BASE_HP)

func _update_hud():
    character_label.text = "🐉 REAL CHP — BATTLE   |   " + character_name
    hp_label.text = "❤️ HP %d   ⚡ Energia %d   🛡️ Escudo %d   💀 Kills %d" % [hp,energy,shield,kills]
    var cd = "PRONTA" if ability_ready else "%ds" % int(ceil(ability_cooldown))
    info_label.text = "Habilidade: " + cd + "   |   UMP   |   50 jogadores (planejado)"
    ability_button.disabled = not ability_ready
    ability_button.text = "🐉 HABILIDADE [" + cd + "]"
